local fun = vim.fn
local api = vim.api
local wo_set = api.nvim_win_set_option
local exec_buf_map = {}
local function prepare_buf(lines, source_buf, reuse_3f)
  local time = os.date("*t")
  local hour = time.hour
  local min = time.min
  local sec = time.sec
  local buf
  if (reuse_3f and exec_buf_map[source_buf]) then
    buf = exec_buf_map[source_buf]
  else
    buf = api.nvim_create_buf(false, true)
  end
  exec_buf_map[source_buf] = buf
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_buf_set_name(buf, string.format("%02d:%02d:%02d", hour, min, sec))
  return buf
end
local function display_output(response, source_buf, reuse_3f)
  local stderr
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for k, v in pairs(response.stderr) do
      local val_23_auto = v.text
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    stderr = tbl_21_auto
  end
  local stdout
  do
    local tbl_21_auto = {}
    local i_22_auto = 0
    for k, v in pairs(response.stdout) do
      local val_23_auto = v.text
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    stdout = tbl_21_auto
  end
  local lines = {("exit code: " .. response.code)}
  table.insert(lines, "stdout:")
  vim.list_extend(lines, stdout)
  table.insert(lines, "stderr:")
  vim.list_extend(lines, stderr)
  local exists = (nil ~= exec_buf_map[source_buf])
  local output_buf = prepare_buf(lines, source_buf, reuse_3f)
  local old_winid = fun.win_getid()
  if not (reuse_3f and exists) then
    vim.cmd("split")
    vim.cmd(("buffer " .. output_buf))
    wo_set(0, "number", false)
    wo_set(0, "relativenumber", false)
    wo_set(0, "spell", false)
    wo_set(0, "cursorline", false)
  else
  end
  return api.nvim_set_current_win(old_winid)
end
local function execute(begin, _end, compiler, options, reuse_3f)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  local source_buf = fun.bufnr()
  options["compilerOptions"] = {executorRequest = true}
  local cmd = require("godbolt.cmd")["build-cmd"](compiler, text, options, "exec")
  local function _5_(_, _0, _1)
    local file = io.open("godbolt_response_exec.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_exec.json")
    os.remove("godbolt_response_exec.json")
    return display_output(vim.json.decode(response), source_buf, reuse_3f)
  end
  return fun.jobstart(cmd, {on_exit = _5_})
end
return {execute = execute}
