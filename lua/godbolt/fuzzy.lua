local fun = vim.fn
local pre_display = (require("godbolt.assembly"))["pre-display"]
local execute = (require("godbolt.execute")).execute
local function transform(entry)
  return {value = (vim.split(entry, " "))[1], display = entry, ordinal = entry}
end
local function fzf(entries, begin, _end, options, exec)
  local function _1_(choice)
    local compiler = (vim.split(choice, " "))[1]
    pre_display(begin, _end, compiler, options)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["fzf#run"]({source = entries, window = {width = 0.9, height = 0.6}, sink = _1_})
end
local function skim(entries, begin, _end, options, exec)
  local function _3_(choice)
    local compiler = (vim.split(choice, " "))[1]
    pre_display(begin, _end, compiler, options)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["skim#run"]({source = entries, window = {width = 0.9, height = 0.6}, sink = _3_})
end
local function telescope(entries, begin, _end, options, exec)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = (require("telescope.config")).values
  local actions = require("telescope.actions")
  local actions_state = require("telescope.actions.state")
  local function _5_(prompt_bufnr, map)
    local function _6_()
      actions.close(prompt_bufnr)
      local compiler = actions_state.get_selected_entry().value
      pre_display(begin, _end, compiler, options)
      if exec then
        return execute(begin, _end, compiler, options)
      else
        return nil
      end
    end
    return (actions.select_default):replace(_6_)
  end
  return pickers.new({}, {prompt_title = "Choose compiler", finder = finders.new_table({results = entries, entry_maker = transform}), sorter = conf.generic_sorter(nil), attach_mappings = _5_}):find()
end
local function fzy(entries, begin, _end, options, exec)
  local function _8_(text)
    return text
  end
  local function _9_(choice)
    local compiler = (vim.split(choice, " "))[1]
    pre_display(begin, _end, compiler, options)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return (require("fzy")).pick_one(entries, "Choose compiler: ", _8_, _9_)
end
local function fuzzy(picker, ft, begin, _end, options, exec)
  local ft0
  do
    local _11_ = ft
    if (_11_ == "cpp") then
      ft0 = "c++"
    elseif (nil ~= _11_) then
      local x = _11_
      ft0 = x
    else
      ft0 = nil
    end
  end
  local cmd = string.format("curl https://godbolt.org/api/compilers/%s", ft0)
  local output = {}
  local jobid
  local function _13_(_, data, _0)
    return vim.list_extend(output, data)
  end
  local function _14_(_, _0, _1)
    local final
    do
      local tbl_14_auto = {}
      local i_15_auto = #tbl_14_auto
      for k, v in ipairs(output) do
        local val_16_auto
        if (k ~= 1) then
          val_16_auto = v
        else
          val_16_auto = nil
        end
        if (nil ~= val_16_auto) then
          i_15_auto = (i_15_auto + 1)
          do end (tbl_14_auto)[i_15_auto] = val_16_auto
        else
        end
      end
      final = tbl_14_auto
    end
    local _18_
    do
      local _17_ = picker
      if (_17_ == "fzf") then
        _18_ = fzf
      elseif (_17_ == "skim") then
        _18_ = skim
      elseif (_17_ == "telescope") then
        _18_ = telescope
      elseif (_17_ == "fzy") then
        _18_ = fzy
      else
        _18_ = nil
      end
    end
    return _18_(final, begin, _end, options, exec)
  end
  jobid = fun.jobstart(cmd, {on_stdout = _13_, on_exit = _14_})
  return nil
end
return {fuzzy = fuzzy}
