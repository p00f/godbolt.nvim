local fun = vim.fn
local api = vim.api
local cmd = vim.cmd
local config = {cpp = {compiler = "g112", options = nil}, c = {compiler = "cg112", options = nil}, rust = {compiler = "r1560", options = nil}}
local function setup(cfg)
  if fun.has("nvim-0.6") then
    if vim.g.godbolt_loaded then
      return nil
    else
      local _1_
      do
        __fnl_global__source_2dasm_2dbufs = {}
        nsid = api.nvim_create_namespace("godbolt")
        if cfg then
          for k, v in pairs(cfg) do
            config[k] = v
          end
        else
        end
        vim.g.godbolt_loaded = true
        _1_ = nil
      end
      if _1_ then
        return api.nvim_err_writeln("neovim 0.6 is required")
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function prepare_buf(text)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, 0, false, vim.split(text, "\n", {trimempty = true}))
  return buf
end
local function setup_aucmd(source_buf, asm_buf)
  cmd("augroup Godbolt")
  cmd(string.format("autocmd CursorMoved <buffer=%s> lua require('godbolt')['smolck-update'](%s, %s)", source_buf, source_buf, asm_buf))
  cmd(string.format("autocmd BufLeave <buffer=%s> lua require('godbolt').clear(%s)", source_buf, source_buf))
  return cmd("augroup END")
end
local function build_cmd(compiler, text, options)
  local json = vim.json.encode({source = text, options = {userArguments = options}})
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local function get_compiler(compiler, options)
  local ft = vim.bo.filetype
  if compiler then
    if ("telescope" == compiler) then
      return {(require("godbolt.telescope"))["compiler-choice"](ft), options}
    else
      return {compiler, options}
    end
  else
    return {config[ft].compiler, config[ft].options}
  end
end
local function display(response, begin)
  local asm
  do
    local str = ""
    for k, v in pairs(response.asm) do
      str = (str .. "\n" .. v.text)
    end
    asm = str
  end
  local source_winid = fun.win_getid()
  local source_bufnr = fun.bufnr()
  local asm_buf = prepare_buf(asm)
  cmd("vsplit")
  cmd(string.format("buffer %d", asm_buf))
  api.nvim_win_set_option(0, "number", false)
  api.nvim_win_set_option(0, "relativenumber", false)
  api.nvim_win_set_option(0, "spell", false)
  api.nvim_win_set_option(0, "cursorline", false)
  api.nvim_set_current_win(source_winid)
  if not (__fnl_global__source_2dasm_2dbufs)[source_bufnr] then
    __fnl_global__source_2dasm_2dbufs[source_bufnr] = {}
  else
  end
  __fnl_global__source_2dasm_2dbufs[source_bufnr][asm_buf] = {asm = response.asm, offset = begin}
  return setup_aucmd(source_bufnr, asm_buf)
end
local function get_then_display(cmd0, begin)
  local output_arr = {}
  local _jobid
  local function _8_(_, data, _0)
    return vim.list_extend(output_arr, data)
  end
  local function _9_(_, _0, _1)
    return display(vim.json.decode(fun.join(output_arr)), begin)
  end
  _jobid = fun.jobstart(cmd0, {on_stdout = _8_, on_exit = _9_})
  return nil
end
local function pre_display(begin, _end, compiler, options)
  if vim.g.godbolt_loaded then
    local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
    local text = fun.join(lines, "\n")
    local chosen_compiler = get_compiler(compiler, options)
    return get_then_display(build_cmd(chosen_compiler[1], text, chosen_compiler[2]), begin)
  else
    return api.nvim_err_writeln("setup function not called")
  end
end
local function clear(source_buf)
  for asm_buf, _ in pairs((__fnl_global__source_2dasm_2dbufs)[source_buf]) do
    api.nvim_buf_clear_namespace(asm_buf, nsid, 0, -1)
  end
  return nil
end
local function smolck_update(source_buf, asm_buf)
  api.nvim_buf_clear_namespace(asm_buf, nsid, 0, -1)
  local entry = (__fnl_global__source_2dasm_2dbufs)[source_buf][asm_buf]
  local offset = entry.offset
  local asm_table = entry.asm
  local linenum = ((fun.getcurpos()[2] - offset) + 1)
  for k, v in pairs(asm_table) do
    if (type(v.source) == "table") then
      if (linenum == v.source.line) then
        vim.highlight.range(asm_buf, nsid, "Visual", {(k - 1), 0}, {(k - 1), 100}, "linewise", true)
      else
      end
    else
    end
  end
  return nil
end
return {["pre-display"] = pre_display, ["smolck-update"] = smolck_update, clear = clear, setup = setup}
