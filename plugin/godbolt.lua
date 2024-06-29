local function complete(_, _0, _1)
  return {"fzf", "fzy", "skim", "telescope"}
end
local function _1_(opts)
  return require("godbolt.cmd").godbolt(opts.line1, opts.line2, opts.bang)
end
vim.api.nvim_create_user_command("Godbolt", _1_, {bang = true, nargs = 0, range = "%"})
local function _2_(opts)
  return require("godbolt.cmd").godbolt(opts.line1, opts.line2, opts.bang, opts.fargs[1])
end
vim.api.nvim_create_user_command("GodboltCompiler", _2_, {bang = true, nargs = 1, complete = complete, range = "%"})
local function setup_highlights(highlights)
  local tbl_19_auto = {}
  local i_20_auto = 0
  for i, v in ipairs(highlights) do
    local val_21_auto
    if (type(v) == "string") then
      local group_name = ("Godbolt" .. i)
      if (string.sub(v, 1, 1) == "#") then
        vim.cmd.highlight(group_name, ("guibg=" .. v))
      elseif pcall(vim.fn.execute, ("highlight " .. v)) then
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
if not (1 == vim.g.godbolt_loaded) then
  vim.g.godbolt_loaded = 1
  _G.__godbolt_map = {}
  _G.__godbolt_exec_buf_map = {}
  _G.__godbolt_nsid = vim.api.nvim_create_namespace("godbolt")
  local config = require("godbolt").config
  if (config.highlights and not vim.tbl_isempty(config.highlights) and (config.highlights[1] ~= "Godbolt1")) then
    config.highlights = setup_highlights(config.highlights)
    return nil
  else
    return nil
  end
else
  return nil
end
