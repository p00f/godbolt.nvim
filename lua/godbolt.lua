local fun = vim.fn
local api = vim.api
local function get(cmd)
  local output_arr = {}
  local jobid
  local function _1_(_, data, _0)
    return vim.list_extend(output_arr, data)
  end
  jobid = fun.jobstart(cmd, {on_stdout = _1_})
  local t = fun.jobwait({jobid})
  local json = fun.join(output_arr)
  return fun.json_decode(json)
end
local function build_cmd(compiler, text, options)
  local json = fun.json_encode({source = text, options = {userArguments = options}})
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local config = {cpp = {compiler = "g112", options = nil}, c = {compiler = "cg112", options = nil}, rust = {compiler = "r1560", options = nil}}
local function setup(cfg)
  for k, v in pairs(cfg) do
    config[k] = v
  end
  return nil
end
local function setup_buf(text)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, 0, false, vim.split(text, "\n", {trimempty = true}))
  return buf
end
local function display()
  local lines
  do
    local _2_ = fun.mode()
    if (_2_ == "n") then
      lines = api.nvim_buf_get_lines(0, 0, -1, true)
    elseif (_2_ == "v") then
      local begin = (fun.getline("'<") - 1)
      local _end = (fun.getline(">'") - 1)
      lines = api.nvim_buf_get_lines(0, begin, _end, true)
    else
      lines = nil
    end
  end
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
  local disp_buf = setup_buf(asm)
  vim.cmd("vsplit")
  vim.cmd(string.format("buffer %d", disp_buf))
  return api.nvim_set_current_win(source_winid)
end
return {display = display}
