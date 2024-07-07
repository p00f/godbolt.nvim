local fun = vim.fn
local api = vim.api
local config = {languages = {cpp = {compiler = "g132", options = {}}, c = {compiler = "cg132", options = {}}, rust = {compiler = "r1730", options = {}}}, auto_cleanup = true, highlight = {cursor = "Visual", lines = {"#222222", "#333333", "#444444", "#555555", "#444444", "#333333"}}, quickfix = {auto_open = false, enable = false}, url = "https://godbolt.org"}
local function setup(cfg)
  if (1 == fun.has("nvim-0.6")) then
    if cfg then
      for k, v in pairs(vim.tbl_deep_extend("force", config, cfg)) do
        config[k] = v
      end
      return nil
    else
      return nil
    end
  else
    return api.nvim_err_writeln("neovim 0.6+ is required")
  end
end
return {config = config, setup = setup}
