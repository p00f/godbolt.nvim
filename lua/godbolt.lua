local fun = vim.fn
local api = vim.api
local config = {cpp = {compiler = "g112", options = nil}, c = {compiler = "cg112", options = nil}, rust = {compiler = "r1560", options = nil}}
local function setup(cfg)
  if vim.g.godbolt_loaded then
    return nil
  else
    __fnl_global__source_2dasm_2dbufs = {}
    nsid = vim.api.nvim_create_namespace("godbolt")
    if cfg then
      for k, v in pairs(cfg) do
        config[k] = v
      end
    else
    end
    vim.g.godbolt_loaded = true
    return nil
  end
end
local function prepare_buf(text)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, 0, false, vim.split(text, "\n", {trimempty = true}))
  return buf
end
local function setup_aucmd(buf, offset)
  vim.cmd("augroup Godbolt")
  vim.cmd(string.format("autocmd CursorMoved <buffer=%s> lua require('godbolt')['smolck-update'](%s, %s)", buf, buf, offset))
  vim.cmd(string.format("autocmd BufLeave <buffer=%s> lua require('godbolt').clear(%s)", buf, buf))
  return vim.cmd("augroup END")
end
local function build_cmd(compiler, text, options)
  local json = fun.json_encode({source = text, options = {userArguments = options}})
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
  local disp_buf = prepare_buf(asm)
  vim.cmd("vsplit")
  vim.cmd(string.format("buffer %d", disp_buf))
  api.nvim_win_set_option(0, "number", false)
  api.nvim_win_set_option(0, "relativenumber", false)
  api.nvim_win_set_option(0, "spell", false)
  api.nvim_win_set_option(0, "cursorline", false)
  api.nvim_set_current_win(source_winid)
  if not (__fnl_global__source_2dasm_2dbufs)[source_bufnr] then
    __fnl_global__source_2dasm_2dbufs[source_bufnr] = {}
  else
  end
  __fnl_global__source_2dasm_2dbufs[source_bufnr][disp_buf] = response.asm
  return setup_aucmd(source_bufnr, begin)
end
local function get_then_display(cmd, begin)
  local output_arr = {}
  local jobid
  local function _6_(_, data, _0)
    return vim.list_extend(output_arr, data)
  end
  local function _7_(_, _0, _1)
    local json = fun.join(output_arr)
    local response = fun.json_decode(json)
    return display(response, begin)
  end
  jobid = fun.jobstart(cmd, {on_stdout = _6_, on_exit = _7_})
  return nil
end
local function pre_display(begin, _end, compiler, options)
  if vim.g.godbolt_loaded then
    local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
    local text = fun.join(lines, "\n")
    local chosen_compiler = get_compiler(compiler, options)
    return get_then_display(build_cmd(chosen_compiler[1], text, chosen_compiler[2]), begin)
  else
    return vim.api.nvim_err_writeln("setup function not called")
  end
end
local function clear(source_buf)
  for disp_buf, asm in pairs((__fnl_global__source_2dasm_2dbufs)[source_buf]) do
    api.nvim_buf_clear_namespace(disp_buf, nsid, 0, -1)
  end
  return nil
end
local function smolck_update(buf, offset)
  clear(buf)
  for disp_buf, asm_table in pairs((__fnl_global__source_2dasm_2dbufs)[buf]) do
    local linenum = ((fun.getcurpos()[2] - offset) + 1)
    for k, v in pairs(asm_table) do
      if (type(v.source) == "table") then
        if (linenum == v.source.line) then
          vim.highlight.range(disp_buf, nsid, "Visual", {(k - 1), 0}, {(k - 1), 100}, "linewise", true)
        else
        end
      else
      end
    end
  end
  return nil
end
return {["pre-display"] = pre_display, ["smolck-update"] = smolck_update, clear = clear, setup = setup}
