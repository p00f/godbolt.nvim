local fun = vim.fn
local api = vim.api
local config = {languages = {cpp = {compiler = "g132", options = {}}, c = {compiler = "cg132", options = {}}, rust = {compiler = "r1730", options = {}}}, quickfix = {auto_open = false, enable = false}, url = "https://godbolt.org"}
local function setup(cfg)
  local _4_
  do
    if cfg then
      for k, v in pairs(cfg) do
        config[k] = v
      end
      _4_ = nil
    else
      _4_ = nil
    end
  end
  if (function(_1_,_2_,_3_) return (_1_ == _2_) and (_2_ == _3_) end)(1,fun.has("nvim-0.6"),_4_) then
    return api.nvim_err_writeln("neovim 0.6+ is required")
  else
    return nil
  end
end
return {config = config, setup = setup}
