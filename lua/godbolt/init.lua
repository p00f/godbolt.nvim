local fun = vim.fn
local api = vim.api
if not vim.g.godbolt_loaded then
  _G["_private-gb-exports"] = {}
else
end
local function setup(cfg)
  if fun.has("nvim-0.6") then
    if not vim.g.godbolt_loaded then
      _G["_private-gb-exports"]["bufmap"] = {}
      _G["_private-gb-exports"]["nsid"] = api.nvim_create_namespace("godbolt")
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
  local file = io.open("godbolt_request.json", "w")
  file:write(json)
  io.close(file)
  local ret = string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary @godbolt_request.json" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler)
  return ret
end
local function godbolt(begin, _end, compiler_arg)
  if vim.g.godbolt_loaded then
    local pre_display = (require("godbolt.assembly"))["pre-display"]
    local execute = (require("godbolt.execute")).execute
    local ft = vim.bo.filetype
    local options = vim.deepcopy(vim.g.godbolt_config[ft].options)
    if compiler_arg then
      local flags = vim.fn.input({prompt = "Flags: ", default = ""})
      do end (options)["userArguments"] = flags
      local _5_ = compiler_arg
      local function _6_()
        local fuzzy = _5_
        return (("telescope" == fuzzy) or ("fzf" == fuzzy) or ("skim" == fuzzy) or ("fzy" == fuzzy))
      end
      if ((nil ~= _5_) and _6_()) then
        local fuzzy = _5_
        return (require("godbolt.fuzzy")).fuzzy(fuzzy, ft, begin, _end, options, (true == vim.b.godbolt_exec))
      elseif true then
        local _ = _5_
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
