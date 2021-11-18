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
  local json
  do
    local str = ""
    for k, v in ipairs(output_arr) do
      str = (str .. v)
    end
    json = str
  end
  return fun.json_decode(json)
end
local function build_cmd(compiler, text, options)
  local json = fun.json_encode({source = text, options = {userArguments = options}})
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local config = {"cpp", {compiler = "g112", options = ""}, "c", {compiler = "cg112", options = ""}, "rust", {compiler = "r1560", options = ""}}
local function setup(cfg)
  for k, v in pairs(cfg) do
    config[k] = v
  end
  return nil
end
local function display()
  local text
  do
    local _2_ = fun.mode()
    if (_2_ == "n") then
      text = api.nvim_buf_get_lines(0, 0, -1)
    elseif (_2_ == "v") then
      local begin = (fun.getline("'<") - 1)
      local _end = (fun.getline(">'") - 1)
      text = api.nvim_buf_get_lines(0, begin, _end)
    else
      text = nil
    end
  end
  local ft = vim.bo.filetype
  local asm = get(build_cmd(config[ft].compiler, text, config[ft].options))
  local winid = fun.win_getid()
  return 1
end
return {display = display}
