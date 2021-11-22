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
  local cmd = (require("godbolt.init"))["build-cmd"](compiler, text, options)
  local output_arr = {}
  local _jobid
  local function _2_(_, data, _0)
    return vim.list_extend(output_arr, data)
  end
  local function _3_(_, _0, _1)
    os.remove("godbolt.json")
    return echo_output(vim.json.decode(fun.join(output_arr)))
  end
  _jobid = fun.jobstart(cmd, {on_stdout = _2_, on_exit = _3_})
  return nil
end
return {execute = execute}
