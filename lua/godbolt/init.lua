local fun = vim.fn
local api = vim.api
local M = {config = {languages = {cpp = {compiler = "g132", options = {}}, c = {compiler = "cg132", options = {}}, rust = {compiler = "r1730", options = {}}}, auto_cleanup = true, highlight = {cursor = "Visual", static = {"#222222", "#333333", "#444444", "#555555", "#444444", "#333333"}}, quickfix = {auto_open = false, enable = false}, url = "https://godbolt.org"}}
M.setup = function(user_config)
  if (1 == fun.has("nvim-0.6")) then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
    return nil
  else
    return api.nvim_err_writeln("neovim 0.6+ is required")
  end
end
return M
