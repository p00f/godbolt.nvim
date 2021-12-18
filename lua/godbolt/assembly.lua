local fun = vim.fn
local api = vim.api
local cmd = vim.cmd
local source_asm_bufs = (_G["_private-gb-exports"]).bufmap
local function prepare_buf(text, name)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, 0, false, vim.split(text, "\n", {trimempty = true}))
  api.nvim_buf_set_name(buf, name)
  return buf
end
local function setup_aucmd(source_buf, asm_buf)
  cmd("augroup Godbolt")
  cmd(string.format("autocmd CursorMoved <buffer=%s> lua require('godbolt.assembly')['smolck-update'](%s, %s)", source_buf, source_buf, asm_buf))
  cmd(string.format("autocmd BufLeave <buffer=%s> lua require('godbolt.assembly').clear(%s)", source_buf, source_buf))
  return cmd("augroup END")
end
local function make_qflist(err, bufnr)
  if next(err) then
    local tbl_15_auto = {}
    local i_16_auto = #tbl_15_auto
    for k, v in ipairs(err) do
      local val_17_auto
      do
        local entry = {text = string.gsub(v.text, "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", ""), bufnr = bufnr}
        if v.tag then
          entry["col"] = v.tag.column
          entry["lnum"] = v.tag.line
        else
        end
        val_17_auto = entry
      end
      if (nil ~= val_17_auto) then
        i_16_auto = (i_16_auto + 1)
        do end (tbl_15_auto)[i_16_auto] = val_17_auto
      else
      end
    end
    return tbl_15_auto
  else
    return nil
  end
end
local function clear(source_buf)
  for asm_buf, _ in pairs(source_asm_bufs[source_buf]) do
    api.nvim_buf_clear_namespace(asm_buf, (_G["_private-gb-exports"]).nsid, 0, -1)
  end
  return nil
end
local function smolck_update(source_buf, asm_buf)
  api.nvim_buf_clear_namespace(asm_buf, (_G["_private-gb-exports"]).nsid, 0, -1)
  local entry = source_asm_bufs[source_buf][asm_buf]
  local offset = entry.offset
  local asm_table = entry.asm
  local linenum = ((fun.getcurpos()[2] - offset) + 1)
  for k, v in pairs(asm_table) do
    if (type(v.source) == "table") then
      if (linenum == v.source.line) then
        vim.highlight.range(asm_buf, (_G["_private-gb-exports"]).nsid, "Visual", {(k - 1), 0}, {(k - 1), 100}, "linewise", true)
      else
      end
    else
    end
  end
  return nil
end
local function display(response, begin, name)
  local asm
  do
    local str = ""
    for k, v in pairs(response.asm) do
      if v.text then
        str = (str .. "\n" .. v.text)
      else
        str = str
      end
    end
    asm = str
  end
  local source_winid = fun.win_getid()
  local source_bufnr = fun.bufnr()
  local qflist = make_qflist(response.stderr, source_bufnr)
  local asm_buf = prepare_buf(asm, name)
  if _G.godbolt_config.quickfix.enable then
    if qflist then
      fun.setqflist(qflist)
      if _G.godbolt_config.quickfix.auto_open then
        vim.cmd("copen")
      else
      end
    else
    end
  else
  end
  if ("<Compilation failed>" == response.asm[1].text) then
    return vim.notify("Compilation failed")
  else
    cmd("vsplit")
    cmd(string.format("buffer %d", asm_buf))
    api.nvim_win_set_option(0, "number", false)
    api.nvim_win_set_option(0, "relativenumber", false)
    api.nvim_win_set_option(0, "spell", false)
    api.nvim_win_set_option(0, "cursorline", false)
    api.nvim_set_current_win(source_winid)
    if not source_asm_bufs[source_bufnr] then
      source_asm_bufs[source_bufnr] = {}
    else
    end
    source_asm_bufs[source_bufnr][asm_buf] = {asm = response.asm, offset = begin}
    return setup_aucmd(source_bufnr, asm_buf)
  end
end
local function pre_display(begin, _end, compiler, options, name)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  local curl_cmd = (require("godbolt.init"))["build-cmd"](compiler, text, options)
  local time = os.date("*t")
  local hour = time.hour
  local min = time.min
  local sec = time.sec
  local _jobid
  local function _12_(_, _0, _1)
    local file = io.open("godbolt_response.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request.json")
    os.remove("godbolt_response.json")
    return display(vim.json.decode(response), begin, string.format("%s %02d:%02d:%02d", (name or compiler), hour, min, sec))
  end
  _jobid = fun.jobstart(curl_cmd, {on_exit = _12_})
  return nil
end
return {["pre-display"] = pre_display, clear = clear, ["smolck-update"] = smolck_update}
