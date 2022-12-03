local _local_1_ = vim
local api = _local_1_["api"]
local cmd = _local_1_["cmd"]
local fun = vim.fn
local fmt = string.format
local term_escapes = "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]"
local wo_set = api.nvim_win_set_option
local map = nil
local nsid = nil
local function prepare_buf(text, name, reuse_3f, source_buf)
  local buf
  local function _2_()
    return (type(map[source_buf]) == "table")
  end
  if (reuse_3f and _2_()) then
    buf = table.maxn(map[source_buf])
  else
    buf = api.nvim_create_buf(false, true)
  end
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(text, "\n", {trimempty = true}))
  api.nvim_buf_set_name(buf, name)
  return buf
end
local function setup_aucmd(source_buf, asm_buf)
  cmd("augroup Godbolt")
  cmd(fmt("autocmd CursorMoved <buffer=%s> lua require('godbolt.assembly')['update-hl'](%s, %s)", source_buf, source_buf, asm_buf))
  cmd(fmt("autocmd BufLeave <buffer=%s> lua require('godbolt.assembly').clear(%s)", source_buf, source_buf))
  return cmd("augroup END")
end
local function make_qflist(err, bufnr)
  if next(err) then
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for k, v in ipairs(err) do
      local val_19_auto
      do
        local entry = {text = string.gsub(v.text, term_escapes, ""), bufnr = bufnr}
        if v.tag then
          entry["col"] = v.tag.column
          entry["lnum"] = v.tag.line
        else
        end
        val_19_auto = entry
      end
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    return tbl_17_auto
  else
    return nil
  end
end
local function clear(source_buf)
  for asm_buf, _ in pairs(map[source_buf]) do
    api.nvim_buf_clear_namespace(asm_buf, nsid, 0, -1)
  end
  return nil
end
local function update_hl(source_buf, asm_buf)
  api.nvim_buf_clear_namespace(asm_buf, nsid, 0, -1)
  local entry = map[source_buf][asm_buf]
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
local function display(response, begin, name, reuse_3f)
  local asm
  if vim.tbl_isempty(response.asm) then
    asm = fmt("No assembly to display (~%d lines filtered)", response.filteredCount)
  else
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
  local config = (require("godbolt")).config
  local source_winid = fun.win_getid()
  local source_buf = fun.bufnr()
  local qflist = make_qflist(response.stderr, source_buf)
  local asm_buf = prepare_buf(asm, name, reuse_3f, source_buf)
  local quickfix_cfg = config.quickfix
  local qf_winid = nil
  if (qflist and quickfix_cfg.enable) then
    fun.setqflist(qflist)
    if quickfix_cfg.auto_open then
      vim.cmd("copen")
      qf_winid = fun.win_getid()
    else
    end
  else
  end
  if (not vim.tbl_isempty(response.asm) and ("<Compilation failed>" == response.asm[1].text)) then
    return vim.notify("godbolt.nvim: Compilation failed")
  else
    api.nvim_set_current_win(source_winid)
    local asm_winid
    if (reuse_3f and map[source_buf]) then
      asm_winid = map[source_buf][asm_buf].winid
    else
      cmd("vsplit")
      asm_winid = api.nvim_get_current_win()
    end
    api.nvim_set_current_win(asm_winid)
    api.nvim_win_set_buf(asm_winid, asm_buf)
    wo_set(asm_winid, "number", false)
    wo_set(asm_winid, "relativenumber", false)
    wo_set(asm_winid, "spell", false)
    wo_set(asm_winid, "cursorline", false)
    if qf_winid then
      api.nvim_set_current_win(qf_winid)
    else
      api.nvim_set_current_win(source_winid)
    end
    if not map[source_buf] then
      map[source_buf] = {}
    else
    end
    map[source_buf][asm_buf] = {asm = response.asm, offset = begin, winid = asm_winid}
    if not vim.tbl_isempty(response.asm) then
      update_hl(source_buf, asm_buf)
      return setup_aucmd(source_buf, asm_buf)
    else
      return nil
    end
  end
end
local function pre_display(begin, _end, compiler, options, reuse_3f)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  local curl_cmd = (require("godbolt.init"))["build-cmd"](compiler, text, options, "asm")
  local time = os.date("*t")
  local hour = time.hour
  local min = time.min
  local sec = time.sec
  local function _18_(_, _0, _1)
    local file = io.open("godbolt_response_asm.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_asm.json")
    os.remove("godbolt_response_asm.json")
    return display(vim.json.decode(response), begin, fmt("%s %02d:%02d:%02d", compiler, hour, min, sec), reuse_3f)
  end
  return fun.jobstart(curl_cmd, {on_exit = _18_})
end
local function init()
  map = {}
  nsid = api.nvim_create_namespace("godbolt")
  return nil
end
return {init = init, map = map, nsid = nsid, ["pre-display"] = pre_display, ["update-hl"] = update_hl, clear = clear}
