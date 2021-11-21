local fun = vim.fn
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
local function fzf(ft, begin, _end, options, exec)
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
  local function _5_(choice)
    local compiler = (vim.split(choice, " "))[1]
    do end (require("godbolt.assembly"))["pre-display"](begin, _end, compiler, options)
    if exec then
      return (require("godbolt.execute")).execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["fzf#run"]({source = lines, window = {width = 0.9, height = 0.6}, sink = _5_})
end
return {fzf = fzf}
