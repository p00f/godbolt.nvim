local fun = vim.fn
local api = vim.api
local config = {languages = {cpp = {compiler = "g132", options = {}}, c = {compiler = "cg132", options = {}}, rust = {compiler = "r1730", options = {}}}, auto_cleanup = true, highlights = {"#222222", "#333333", "#444444", "#555555", "#444444", "#333333"}, quickfix = {auto_open = false, enable = false}, url = "https://godbolt.org"}
local function setup_highlights(highlights)
  local tbl_19_auto = {}
  local i_20_auto = 0
  for i, v in ipairs(highlights) do
    local val_21_auto
    if (type(v) == "string") then
      local group_name = ("Godbolt" .. i)
      if (string.sub(v, 1, 1) == "#") then
        vim.cmd.highlight(group_name, ("guibg=" .. v))
      elseif pcall(fun.execute, ("highlight " .. v)) then
        vim.cmd.highlight(group_name, "link", v)
      else
      end
      val_21_auto = group_name
    else
      val_21_auto = nil
    end
    if (nil ~= val_21_auto) then
      i_20_auto = (i_20_auto + 1)
      do end (tbl_19_auto)[i_20_auto] = val_21_auto
    else
    end
  end
  return tbl_19_auto
end
local function setup(cfg)
  if (1 == fun.has("nvim-0.6")) then
    vim.tbl_extend("force", config, cfg)
    config.highlights = setup_highlights(config.highlights)
    return nil
  else
    return api.nvim_err_writeln("neovim 0.6+ is required")
  end
end
return {config = config, setup = setup}
