local fun = vim.fn
local api = vim.api
local nsid = vim.api.nvim_create_namespace("godbolt")
local config = {cpp = {compiler = "g112", options = nil}, c = {compiler = "cg112", options = nil}, rust = {compiler = "r1560", options = nil}}
local function setup(cfg)
  if vim.g.godbolt_loaded then
    return nil
  else
    __fnl_global__source_2dasm_2dbufs = {}
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
local function get(cmd)
  local output_arr = {}
  local jobid
  local function _3_(_, data, _0)
    return vim.list_extend(output_arr, data)
  end
  jobid = fun.jobstart(cmd, {on_stdout = _3_})
  local t = fun.jobwait({jobid})
  local json = fun.join(output_arr)
  return fun.json_decode(json)
end
local function build_cmd(compiler, text, options)
  local json = fun.json_encode({source = text, options = {userArguments = options}})
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local function setup_aucmd(buf, offset)
  vim.cmd("augroup Godbolt")
  vim.cmd(string.format("autocmd CursorHold <buffer=%s> lua require('godbolt').highlight(%s, %s)", buf, buf, offset))
  vim.cmd(string.format("autocmd CursorMoved,BufLeave <buffer=%s> lua require('godbolt').clear(%s)", buf, buf))
  return vim.cmd("augroup END")
end
local function prepare_buf(text)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, 0, false, vim.split(text, "\n", {trimempty = true}))
  return buf
end
local function display(begin, _end)
  if vim.g.godbolt_loaded then
    local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
    local text = fun.join(lines, "\n")
    local ft = vim.bo.filetype
    local response = get(build_cmd(config[ft].compiler, text, config[ft].options))
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
    api.nvim_set_current_win(source_winid)
    do end (__fnl_global__source_2dasm_2dbufs)[source_bufnr] = {disp_buf, response.asm}
    return setup_aucmd(source_bufnr, begin)
  else
    return vim.api.nvim_err_writeln("setup function not called")
  end
end
local function clear(buf)
  return vim.api.nvim_buf_clear_namespace((__fnl_global__source_2dasm_2dbufs)[buf][1], nsid, 0, -1)
end
local function highlight(buf, offset)
  local disp_buf = (__fnl_global__source_2dasm_2dbufs)[buf][1]
  local asm_table = (__fnl_global__source_2dasm_2dbufs)[buf][2]
  local linenum = fun.getcurpos()[2]
  linenum = (linenum - (offset - 1))
  for k, v in pairs(asm_table) do
    if (type(v.source) == "table") then
      if (linenum == v.source.line) then
        vim.highlight.range(disp_buf, nsid, "Visual", {(k - 1), 0}, {(k - 1), 100}, "linewise", true)
      else
      end
    else
    end
  end
  return nil
end
return {display = display, highlight = highlight, clear = clear, setup = setup}
