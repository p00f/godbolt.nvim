local fun = vim.fn
local api = vim.api
local config = {languages = {cpp = {compiler = "g132", options = {}}, c = {compiler = "cg132", options = {}}, rust = {compiler = "r1730", options = {}}}, auto_cleanup = true, highlights = {"#222222", "#333333", "#444444", "#555555", "#444444", "#333333"}, quickfix = {auto_open = false, enable = false}, url = "https://godbolt.org"}
local function setup(cfg)
  if (1 == fun.has("nvim-0.6")) then
    return vim.tbl_extend("force", config, cfg)
  else
    return api.nvim_err_writeln("neovim 0.6+ is required")
  end
end
return {config = config, setup = setup}
