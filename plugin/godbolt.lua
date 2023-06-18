local function complete(_, _0, _1)
  return {"fzf", "fzy", "skim", "telescope"}
end
local function _1_(opts)
  return (require("godbolt.cmd")).godbolt(opts.line1, opts.line2, opts.bang)
end
vim.api.nvim_create_user_command("Godbolt", _1_, {bang = true, nargs = 0, range = "%"})
local function _2_(opts)
  return (require("godbolt.cmd")).godbolt(opts.line1, opts.line2, opts.bang, opts.fargs[1])
end
vim.api.nvim_create_user_command("GodboltCompiler", _2_, {bang = true, nargs = 1, complete = complete, range = "%"})
if not (1 == vim.g.godbolt_loaded) then
  vim.g.godbolt_loaded = 1
  _G.__godbolt_map = {}
  _G.__godbolt_exec_buf_map = {}
  _G.__godbolt_nsid = vim.api.nvim_create_namespace("godbolt")
  return nil
else
  return nil
end
