local fun = vim.fn
local api = vim.api
if not vim.g.godbolt_loaded then
  _G["gb-exports"] = {}
else
end
local function setup(cfg)
  if fun.has("nvim-0.6") then
    if not vim.g.godbolt_loaded then
      _G["gb-exports"]["bufmap"] = {}
      _G["gb-exports"]["nsid"] = api.nvim_create_namespace("godbolt")
      vim.g.godbolt_config = {cpp = {compiler = "g112", options = {}}, c = {compiler = "cg112", options = {}}, rust = {compiler = "r1560", options = {}}}
      if cfg then
        for k, v in pairs(cfg) do
          vim.g.godbolt_config[k] = v
        end
      else
      end
      vim.g.godbolt_loaded = true
      return nil
    else
      return nil
    end
  else
    return api.nvim_err_writeln("neovim 0.6 is required")
  end
end
local function build_cmd(compiler, text, options)
  local json = vim.json.encode({source = text, options = options})
  json:gsub("'", "\\'")
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local function godbolt(begin, _end, compiler_arg, flags)
  if vim.g.godbolt_loaded then
    local pre_display = (require("godbolt.assembly"))["pre-display"]
    local execute = (require("godbolt.execute")).execute
    local ft = vim.bo.filetype
    local options = vim.deepcopy(vim.g.godbolt_config[ft].options)
    if flags then
      options["userArguments"] = flags
    else
    end
    if compiler_arg then
      local _6_ = compiler_arg
      local function _7_()
        local fuzzy = _6_
        return (("telescope" == fuzzy) or ("fzf" == fuzzy) or ("skim" == fuzzy))
      end
      if ((nil ~= _6_) and _7_()) then
        local fuzzy = _6_
        return (require("godbolt.fuzzy")).fuzzy(fuzzy, ft, begin, _end, options, (true == vim.b.godbolt_exec))
      elseif true then
        local _ = _6_
        pre_display(begin, _end, compiler_arg, options)
        if vim.b.godbolt_exec then
          return execute(begin, _end, compiler_arg, options)
        else
          return nil
        end
      else
        return nil
      end
    else
      local def_comp = vim.g.godbolt_config[ft].compiler
      pre_display(begin, _end, def_comp, options)
      if vim.b.godbolt_exec then
        return execute(begin, _end, def_comp, options)
      else
        return nil
      end
    end
  else
    return api.nvim_err_writeln("setup function not called")
  end
end
return {setup = setup, ["build-cmd"] = build_cmd, godbolt = godbolt}
