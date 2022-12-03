local fun = vim.fn
local api = vim.api
local wo_set = api.nvim_win_set_option
local function prepare_buf(lines)
  local time = os.date("*t")
  local hour = time.hour
  local min = time.min
  local sec = time.sec
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, 0, false, lines)
  api.nvim_buf_set_name(buf, string.format("%02d:%02d:%02d", hour, min, sec))
  return buf
end
local function display_output(response)
  local stderr
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for k, v in pairs(response.stderr) do
      local val_19_auto = v.text
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    stderr = tbl_17_auto
  end
  local stdout
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for k, v in pairs(response.stdout) do
      local val_19_auto = v.text
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    stdout = tbl_17_auto
  end
  local lines = {("exit code: " .. response.code)}
  table.insert(lines, "stdout:")
  vim.list_extend(lines, stdout)
  table.insert(lines, "stderr:")
  vim.list_extend(lines, stderr)
  local output_buf = prepare_buf(lines)
  local old_winid = fun.win_getid()
  vim.cmd("split")
  vim.cmd(("buffer " .. output_buf))
  wo_set(0, "number", false)
  wo_set(0, "relativenumber", false)
  wo_set(0, "spell", false)
  wo_set(0, "cursorline", false)
  return api.nvim_set_current_win(old_winid)
end
local function execute(begin, _end, compiler, options)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  do end (options)["compilerOptions"] = {executorRequest = true}
  local cmd = (require("godbolt.init"))["build-cmd"](compiler, text, options, "exec")
  local function _3_(_, _0, _1)
    local file = io.open("godbolt_response_exec.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_exec.json")
    os.remove("godbolt_response_exec.json")
    return display_output(vim.json.decode(response))
  end
  return fun.jobstart(cmd, {on_exit = _3_})
end
return {execute = execute}
