local fun = vim.fn
local api = vim.api
local function echo_output(response)
  if (0 == response.code) then
    local output
    do
      local str = ""
      for k, v in pairs(response.stdout) do
        str = (str .. "\n" .. v.text)
      end
      output = str
    end
    return api.nvim_echo({{("Output:" .. output)}}, true, {})
  else
    local err
    do
      local str = ""
      for k, v in pairs(response.stderr) do
        str = (str .. "\n" .. v.text)
      end
      err = str
    end
    return api.nvim_err_writeln(err)
  end
end
local function execute(begin, _end, compiler, options)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  do end (options)["compilerOptions"] = {executorRequest = true}
  local cmd = (require("godbolt.init"))["build-cmd"](compiler, text, options, "exec")
  local output_arr = {}
  local _jobid
  local function _2_(_, _0, _1)
    local file = io.open("godbolt_response_exec.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_exec.json")
    os.remove("godbolt_response_exec.json")
    return echo_output(vim.json.decode(response))
  end
  _jobid = fun.jobstart(cmd, {on_exit = _2_})
  return nil
end
return {execute = execute}
