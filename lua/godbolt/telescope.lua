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
local function telescope(ft, begin, _end, options, exec)
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
  local function _5_(prompt_bufnr, map)
    local function _6_()
      actions.close(prompt_bufnr)
      local compiler = actions_state.get_selected_entry().value
      do end (require("godbolt.assembly"))["pre-display"](begin, _end, compiler, options)
      if exec then
        return (require("godbolt.execute")).execute(begin, _end, compiler, options)
      else
        return nil
      end
    end
    return (actions.select_default):replace(_6_)
  end
  return pickers.new({}, {prompt_title = "Choose compiler", finder = finders.new_table({results = lines, entry_maker = transform}), sorter = conf.generic_sorter(nil), attach_mappings = _5_}):find()
end
return {telescope = telescope}
