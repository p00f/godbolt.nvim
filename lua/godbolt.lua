local fun = vim.fn
local api = vim.api
local nsid = vim.api.nvim_create_namespace("godbolt")
local function get_compiler_list(cmd)
  local op = {}
  local jobid
  local function _1_(_, data, _0)
    return vim.list_extend(op, data)
  end
  jobid = vim.fn.jobstart(cmd, {on_stdout = _1_})
  local t = vim.fn.jobwait({jobid})
  local final = {}
  for k, v in pairs(op) do
    if (k ~= 1) then
      table.insert(final, v)
    else
    end
  end
  return final
end
local function transform(entry)
  return {value = (vim.split(entry, " "))[1], display = entry, ordinal = entry}
end
local function tscope(ft)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = (require("telescope.config")).values
  local actions = require("telescope.actions")
  local actions_state = require("telescope.actions.state")
  local ft0
  do
    local _3_ = ft
    if (_3_ == "cpp") then
      ft0 = "c++"
    elseif (nil ~= _3_) then
      local x = _3_
      ft0 = x
    else
      ft0 = nil
    end
  end
  local cmd = string.format("curl https://godbolt.org/api/compilers/%s", ft0)
  local lines = get_compiler_list(cmd)
  local compiler = nil
  local function _5_(prompt_bufnr, map)
    local function _6_()
      actions.close(prompt_bufnr)
      local selection = actions_state.get_selected_entry()
      compiler = selection.value
      return nil
    end
    return (actions.select_default):replace(_6_)
  end
  pickers.new(nil, {prompt_title = "Choose compiler", finder = finders.new_table({results = lines, entry_maker = transform}), sorter = conf.generic_sorter(nil), attach_mappings = _5_}):find()
  return compiler
end
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
local function prepare_buf(text)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "filetype", "asm")
  api.nvim_buf_set_lines(buf, 0, 0, false, vim.split(text, "\n", {trimempty = true}))
  return buf
end
local function setup_aucmd(buf, offset)
  vim.cmd("augroup Godbolt")
  vim.cmd(string.format("autocmd CursorHold <buffer=%s> lua require('godbolt').highlight(%s, %s)", buf, buf, offset))
  vim.cmd(string.format("autocmd CursorMoved,BufLeave <buffer=%s> lua require('godbolt').clear(%s)", buf, buf))
  return vim.cmd("augroup END")
end
local function display(response, begin)
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
  api.nvim_win_set_option(0, "number", false)
  api.nvim_win_set_option(0, "relativenumber", false)
  api.nvim_win_set_option(0, "spell", false)
  api.nvim_win_set_option(0, "cursorline", false)
  api.nvim_set_current_win(source_winid)
  do end (__fnl_global__source_2dasm_2dbufs)[source_bufnr] = {disp_buf, response.asm}
  return setup_aucmd(source_bufnr, begin)
end
local function get(cmd, begin)
  local output_arr = {}
  local jobid
  local function _9_(_, data, _0)
    return vim.list_extend(output_arr, data)
  end
  local function _10_(_, _0, _1)
    local json = fun.join(output_arr)
    local response = fun.json_decode(json)
    return display(response, begin)
  end
  jobid = fun.jobstart(cmd, {on_stdout = _9_, on_exit = _10_})
  return nil
end
local function build_cmd(compiler, text, options)
  local json = fun.json_encode({source = text, options = {userArguments = options}})
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local function get_compiler(compiler, options)
  if compiler then
    if ("telescope" == compiler) then
      return {tscope(vim.bo.filetype), options}
    else
      return {compiler, options}
    end
  else
    local ft = vim.bo.filetype
    return {config[ft].compiler, config[ft].options}
  end
end
local function pre_display(begin, _end, compiler, options)
  if vim.g.godbolt_loaded then
    local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
    local text = fun.join(lines, "\n")
    local chosen_compiler = get_compiler(compiler, options)
    return get(build_cmd(chosen_compiler[1], text, chosen_compiler[2]), begin)
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
  local linenum = ((fun.getcurpos()[2] - offset) + 1)
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
return {["pre-display"] = pre_display, highlight = highlight, clear = clear, setup = setup}
