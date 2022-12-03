local fun = vim.fn
local api = vim.api
local config = {languages = {cpp = {compiler = "g127", options = {}}, c = {compiler = "cg127", options = {}}, rust = {compiler = "r1650", options = {}}}, quickfix = {enable = false, auto_open = false}, url = "https://godbolt.org"}
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
local function build_cmd(compiler, text, options, exec_asm_3f)
  local json = vim.json.encode({source = text, options = options})
  local config0 = (require("godbolt")).config
  local file = io.open(string.format("godbolt_request_%s.json", exec_asm_3f), "w")
  file:write(json)
  io.close(file)
  return string.format(("curl %s/api/compiler/'%s'/compile" .. " --data-binary @godbolt_request_%s.json" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'" .. " --output godbolt_response_%s.json"), config0.url, compiler, exec_asm_3f, exec_asm_3f)
end
local function godbolt(begin, _end, reuse_3f, compiler)
  local pre_display = (require("godbolt.assembly"))["pre-display"]
  local execute = (require("godbolt.execute")).execute
  local fuzzy = (require("godbolt.fuzzy")).fuzzy
  local ft = vim.bo.filetype
  local config0 = (require("godbolt")).config
  local compiler0 = (compiler or (config0.languages)[ft].compiler)
  local options
  if (config0.languages)[ft] then
    options = vim.deepcopy((config0.languages)[ft].options)
  else
    options = {}
  end
  local flags = vim.fn.input({prompt = "Flags: ", default = (options.userArguments or "")})
  do end (options)["userArguments"] = flags
  local fuzzy_3f
  do
    local matches = false
    for k, v in pairs({"telescope", "fzf", "skim", "fzy"}) do
      if (v == compiler0) then
        matches = true
      else
        matches = matches
      end
    end
    fuzzy_3f = matches
  end
  if fuzzy_3f then
    return fuzzy(compiler0, ft, begin, _end, options, (true == vim.b.godbolt_exec), reuse_3f)
  else
    pre_display(begin, _end, compiler0, options, reuse_3f)
    if vim.b.godbolt_exec then
      return execute(begin, _end, compiler0, options)
    else
      return nil
    end
  end
end
return {config = config, setup = setup, ["build-cmd"] = build_cmd, godbolt = godbolt}
