local _local_1_ = vim
local api = _local_1_["api"]
local cmd = _local_1_["cmd"]
local fun = vim.fn
local fmt = string.format
local term_escapes = "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]"
local wo_set = api.nvim_win_set_option
local map = _G.__godbolt_map
local nsid = _G.__godbolt_nsid
local function prepare_buf(text, name, reuse_3f, source_buf)
  local buf
  local function _2_(...)
    return (type(map[source_buf]) == "table")
  end
  if (reuse_3f and _2_()) then
    buf = table.maxn(map[source_buf])
  else
    buf = api.nvim_create_buf(false, true)
  end
  api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(text, "\n", {trimempty = true}))
  api.nvim_buf_set_name(buf, name)
  do
    local _4_ = vim.bo[buf]
    _4_["filetype"] = "asm"
    _4_["bufhidden"] = "unload"
    _4_["modifiable"] = false
  end
  return buf
end
local function get_current_line()
  return fun.getcurpos()[2]
end
local function find_source(asm_buffer)
  local source_buffer_ret = nil
  for source_buffer, asm_buffers in pairs(map) do
    if source_buffer_ret then break end
    if asm_buffers[asm_buffer] then
      source_buffer_ret = source_buffer
    else
    end
  end
  return source_buffer_ret
end
local function count_source_line(entry, asm_line)
  local source
  do
    local t_6_ = entry
    if (nil ~= t_6_) then
      t_6_ = t_6_.asm
    else
    end
    if (nil ~= t_6_) then
      t_6_ = t_6_[asm_line]
    else
    end
    if (nil ~= t_6_) then
      t_6_ = t_6_.source
    else
    end
    source = t_6_
  end
  if ((source ~= nil) and (type(source) == "table") and (source.file == vim.NIL)) then
    return (source.line + (entry.offset - 1))
  else
    return nil
  end
end
local function get_source_line(source_buffer, asm_buffer, asm_line)
  local _12_
  do
    local t_11_ = map
    if (nil ~= t_11_) then
      t_11_ = t_11_[source_buffer]
    else
    end
    if (nil ~= t_11_) then
      t_11_ = t_11_[asm_buffer]
    else
    end
    _12_ = t_11_
  end
  return count_source_line(_12_, asm_line)
end
local function cyclic_lookup(array, index)
  return array[(1 + (index % #array))]
end
local function update_hl(source_buffer, cursor_line)
  api.nvim_buf_clear_namespace(source_buffer, nsid, 0, -1)
  local highlighted_source = {}
  local highlights = require("godbolt").config.highlights
  for asm_buffer, entry in pairs(map[source_buffer]) do
    api.nvim_buf_clear_namespace(asm_buffer, nsid, 0, -1)
    for line, _ in ipairs(entry.asm) do
      local source_line = count_source_line(entry, line)
      if (source_line ~= nil) then
        local group
        if (cursor_line == source_line) then
          group = "Visual"
        else
          group = cyclic_lookup(highlights, source_line)
        end
        api.nvim_buf_add_highlight(asm_buffer, nsid, group, (line - 1), 0, -1)
        if not vim.tbl_contains(highlighted_source, source_line) then
          api.nvim_buf_add_highlight(source_buffer, nsid, group, (source_line - 1), 0, -1)
          table.insert(highlighted_source, source_line)
        else
        end
      else
      end
    end
  end
  return nil
end
local function update_source(options)
  local function _18_(...)
    local t_19_ = options
    if (nil ~= t_19_) then
      t_19_ = t_19_.buf
    else
    end
    return t_19_
  end
  return update_hl((_18_() or fun.bufnr()), get_current_line())
end
local function remove_asm(source_buffer, asm_buffer)
  api.nvim_buf_clear_namespace(asm_buffer, nsid, 0, -1)
  do end (map[source_buffer])[asm_buffer] = nil
  return nil
end
local function remove_source(source_buffer)
  api.nvim_buf_clear_namespace(source_buffer, nsid, 0, -1)
  api.nvim_del_augroup_by_name("Godbolt")
  if (require("godbolt").config.auto_cleanup and (nil ~= map[source_buffer])) then
    for asm_buffer, _ in pairs(map[source_buffer]) do
      api.nvim_buf_delete(asm_buffer, {})
    end
  else
  end
  map[source_buffer] = nil
  return nil
end
local function clear_source(options)
  local function _22_(...)
    local t_23_ = options
    if (nil ~= t_23_) then
      t_23_ = t_23_.buf
    else
    end
    return t_23_
  end
  return remove_source((_22_() or fun.bufnr()))
end
local function update_asm(options)
  local asm_buffer
  local function _25_(...)
    local t_26_ = options
    if (nil ~= t_26_) then
      t_26_ = t_26_.buf
    else
    end
    return t_26_
  end
  asm_buffer = (_25_() or fun.bufnr())
  local source_buffer = find_source(asm_buffer)
  local asm_line = get_current_line()
  local source_line = get_source_line(source_buffer, asm_buffer, asm_line)
  return update_hl(source_buffer, source_line)
end
local function clear_asm(options)
  local asm_buffer
  local function _28_(...)
    local t_29_ = options
    if (nil ~= t_29_) then
      t_29_ = t_29_.buf
    else
    end
    return t_29_
  end
  asm_buffer = (_28_() or fun.bufnr())
  local source_buffer = find_source(asm_buffer)
  remove_asm(source_buffer, asm_buffer)
  if (require("godbolt").config.auto_cleanup and (0 == vim.tbl_count(map[source_buffer]))) then
    return remove_source(source_buffer)
  else
    return nil
  end
end
local function setup_aucmd(source_buf, asm_buf)
  cmd("augroup Godbolt")
  cmd(fmt("autocmd CursorMoved,BufEnter <buffer=%s> lua require('godbolt.assembly')['update-source']()", source_buf))
  cmd(fmt("autocmd CursorMoved,BufEnter <buffer=%s> lua require('godbolt.assembly')['update-asm']()", asm_buf))
  cmd(fmt("autocmd BufUnload <buffer=%s> lua require('godbolt.assembly')['clear-source']()", source_buf))
  cmd(fmt("autocmd BufUnload <buffer=%s> lua require('godbolt.assembly')['clear-asm']()", asm_buf))
  return cmd("augroup END")
end
local function make_qflist(err, bufnr)
  if next(err) then
    local tbl_19_auto = {}
    local i_20_auto = 0
    for _, v in ipairs(err) do
      local val_21_auto
      do
        local entry = {text = string.gsub(v.text, term_escapes, ""), bufnr = bufnr}
        if v.tag then
          entry["col"] = v.tag.column
          entry["lnum"] = v.tag.line
        else
        end
        val_21_auto = entry
      end
      if (nil ~= val_21_auto) then
        i_20_auto = (i_20_auto + 1)
        do end (tbl_19_auto)[i_20_auto] = val_21_auto
      else
      end
    end
    return tbl_19_auto
  else
    return nil
  end
end
local function clear(source_buf)
  api.nvim_buf_clear_namespace(source_buf, nsid, 0, -1)
  api.nvim_del_augroup_by_name("Godbolt")
  for asm_buf, _ in pairs(map[source_buf]) do
    api.nvim_buf_clear_namespace(asm_buf, nsid, 0, -1)
  end
  map[source_buf] = nil
  return nil
end
local function display(response, begin, name, reuse_3f)
  local asm
  if vim.tbl_isempty(response.asm) then
    asm = fmt("No assembly to display (~%d lines filtered)", response.filteredCount)
  else
    local str = ""
    for _, v in pairs(response.asm) do
      if v.text then
        str = (str .. "\n" .. v.text)
      else
        str = str
      end
    end
    asm = str
  end
  local config = require("godbolt").config
  local source_winid = fun.win_getid()
  local source_buf = fun.bufnr()
  local qflist = make_qflist(response.stderr, source_buf)
  local asm_buf = prepare_buf(asm, name, reuse_3f, source_buf)
  local qf_winid = nil
  if (qflist and config.quickfix.enable) then
    fun.setqflist(qflist)
    if config.quickfix.auto_open then
      vim.cmd.copen()
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
      update_hl(source_buf)
      return setup_aucmd(source_buf, asm_buf)
    else
      return nil
    end
  end
end
local function pre_display(begin, _end, compiler, options, reuse_3f)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  local curl_cmd = require("godbolt.cmd")["build-cmd"](compiler, text, options, "asm")
  local time = os.date("*t")
  local hour = time.hour
  local min = time.min
  local sec = time.sec
  local function _44_(_, _0, _1)
    local file = io.open("godbolt_response_asm.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_asm.json")
    os.remove("godbolt_response_asm.json")
    return display(vim.json.decode(response), begin, fmt("%s %02d:%02d:%02d", compiler, hour, min, sec), reuse_3f)
  end
  return fun.jobstart(curl_cmd, {on_exit = _44_})
end
return {map = map, nsid = nsid, ["pre-display"] = pre_display, ["update-hl"] = update_hl, ["update-source"] = update_source, ["update-asm"] = update_asm, ["clear-source"] = clear_source, ["clear-asm"] = clear_asm, clear = clear}
