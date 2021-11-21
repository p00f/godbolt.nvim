local fun = vim.fn
local api = vim.api
if not vim.g.godbolt_loaded then
  __fnl_global__gb_2dexports = {}
else
end
local godbolt_config = {cpp = {compiler = "g112", options = {}}, c = {compiler = "cg112", options = {}}, rust = {compiler = "r1560", options = {}}}
local function setup(cfg)
  if fun.has("nvim-0.6") then
    if vim.g.godbolt_loaded then
      return nil
    else
      local _2_
      do
        __fnl_global__gb_2dexports["bufmap"] = {}
        __fnl_global__gb_2dexports["nsid"] = api.nvim_create_namespace("godbolt")
        if cfg then
          for k, v in pairs(cfg) do
            godbolt_config[k] = v
          end
        else
        end
        vim.g.godbolt_loaded = true
        _2_ = nil
      end
      if _2_ then
        return api.nvim_err_writeln("neovim 0.6 is required")
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function build_cmd(compiler, text, options)
  local json = vim.json.encode({source = text, options = options})
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary '%s'" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'"), compiler, json)
end
local function get_compiler(compiler, flags)
  local ft = vim.bo.filetype
  local options = godbolt_config[ft].options
  options["userArguments"] = flags
  if compiler then
    if ("telescope" == compiler) then
      return {(require("godbolt.telescope"))["compiler-choice"](ft), options}
    else
      return {compiler, options}
    end
  else
    return {godbolt_config[ft].compiler, godbolt_config[ft].options}
  end
end
local function godbolt(begin, _end, compiler, flags)
  local pre_display = (require("godbolt.assembly"))["pre-display"]
  local execute = (require("godbolt.execute")).execute
  pre_display(begin, _end, compiler, flags)
  if vim.b.godbolt_exec then
    return execute(begin, _end, compiler, flags)
  else
    return nil
  end
end
return {setup = setup, ["build-cmd"] = build_cmd, ["get-compiler"] = get_compiler, godbolt = godbolt}
