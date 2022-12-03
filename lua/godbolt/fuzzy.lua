local fun = vim.fn
local pre_display = (require("godbolt.assembly"))["pre-display"]
local execute = (require("godbolt.execute")).execute
local function transform(entry)
  return {value = (vim.split(entry, " "))[1], display = entry, ordinal = entry}
end
local function fzf(entries, begin, _end, options, exec, reuse_3f)
  local maxlen
  do
    local current_maxlen = -1
    for k, v in pairs(entries) do
      local len = fun.len(v)
      if (len > current_maxlen) then
        current_maxlen = len
      else
        current_maxlen = current_maxlen
      end
    end
    maxlen = current_maxlen
  end
  local width = ((maxlen / vim.o.columns) + 0.05)
  local function _2_(choice)
    local compiler = (vim.split(choice, " "))[1]
    pre_display(begin, _end, compiler, options, reuse_3f)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["fzf#run"]({source = entries, window = {width = width, height = 0.6}, sink = _2_})
end
local function skim(entries, begin, _end, options, exec, reuse_3f)
  local maxlen
  do
    local current_maxlen = -1
    for k, v in pairs(entries) do
      local len = fun.len(v)
      if (len > current_maxlen) then
        current_maxlen = len
      else
        current_maxlen = current_maxlen
      end
    end
    maxlen = current_maxlen
  end
  local width = ((maxlen / vim.o.columns) + 0.05)
  local function _5_(choice)
    local compiler = (vim.split(choice, " "))[1]
    pre_display(begin, _end, compiler, options, reuse_3f)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["skim#run"]({source = entries, window = {width = width, height = 0.6}, sink = _5_})
end
local function telescope(entries, begin, _end, options, exec, reuse_3f)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = (require("telescope.config")).values
  local actions = require("telescope.actions")
  local actions_state = require("telescope.actions.state")
  local function _7_(prompt_bufnr, map)
    local function _8_()
      actions.close(prompt_bufnr)
      local compiler = actions_state.get_selected_entry().value
      pre_display(begin, _end, compiler, options, reuse_3f)
      if exec then
        return execute(begin, _end, compiler, options)
      else
        return nil
      end
    end
    return (actions.select_default):replace(_8_)
  end
  return pickers.new({}, {prompt_title = "Choose compiler", finder = finders.new_table({results = entries, entry_maker = transform}), sorter = conf.generic_sorter(nil), attach_mappings = _7_}):find()
end
local function fzy(entries, begin, _end, options, exec, reuse_3f)
  local function _10_(text)
    return text
  end
  local function _11_(choice)
    local compiler = (vim.split(choice, " "))[1]
    pre_display(begin, _end, compiler, options, reuse_3f)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return (require("fzy")).pick_one(entries, "Choose compiler: ", _10_, _11_)
end
local function fuzzy(picker, ft, begin, _end, options, exec, reuse_3f)
  local ft0
  do
    local _13_ = ft
    if (_13_ == "cpp") then
      ft0 = "c++"
    elseif (nil ~= _13_) then
      local x = _13_
      ft0 = x
    else
      ft0 = nil
    end
  end
  local url = (require("godbolt")).config.url
  local cmd = string.format("curl %s/api/compilers/%s", url, ft0)
  local output = {}
  local function _15_(_, data, _0)
    return vim.list_extend(output, data)
  end
  local function _16_(_, _0, _1)
    local entries
    do
      local tbl_17_auto = {}
      local i_18_auto = #tbl_17_auto
      for k, v in ipairs(output) do
        local val_19_auto
        if (k ~= 1) then
          val_19_auto = v
        else
          val_19_auto = nil
        end
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      entries = tbl_17_auto
    end
    local _20_
    do
      local _19_ = picker
      if (_19_ == "fzf") then
        _20_ = fzf
      elseif (_19_ == "skim") then
        _20_ = skim
      elseif (_19_ == "telescope") then
        _20_ = telescope
      elseif (_19_ == "fzy") then
        _20_ = fzy
      else
        _20_ = nil
      end
    end
    return _20_(entries, begin, _end, options, exec, reuse_3f)
  end
  return fun.jobstart(cmd, {on_stdout = _15_, on_exit = _16_, stdout_buffered = true})
end
return {fuzzy = fuzzy}
