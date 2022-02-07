local fun = vim.fn
local api = vim.api
local M = {}
M.setup = function(cfg)
  if (1 == fun.has("nvim-0.6")) then
    if not vim.g.godbolt_loaded then
      do end (require("godbolt.assembly")).init()
      M.config = {cpp = {compiler = "g112", options = {}}, c = {compiler = "cg112", options = {}}, rust = {compiler = "r1560", options = {}}, quickfix = {enable = false, auto_open = false}}
      if cfg then
        for k, v in pairs(cfg) do
          M.config[k] = v
        end
      else
      end
      vim.g.godbolt_loaded = true
      return nil
    else
      return nil
    end
  else
    return api.nvim_err_writeln("neovim 0.6+ is required")
  end
end
M["build-cmd"] = function(compiler, text, options, exec_asm_3f)
  local json = vim.json.encode({source = text, options = options})
  local file = io.open(string.format("godbolt_request_%s.json", exec_asm_3f), "w")
  file:write(json)
  io.close(file)
  return string.format(("curl https://godbolt.org/api/compiler/'%s'/compile" .. " --data-binary @godbolt_request_%s.json" .. " --header 'Accept: application/json'" .. " --header 'Content-Type: application/json'" .. " --output godbolt_response_%s.json"), compiler, exec_asm_3f, exec_asm_3f)
end
M.godbolt = function(begin, _end, reuse_3f, compiler)
  if vim.g.godbolt_loaded then
    local pre_display = (require("godbolt.assembly"))["pre-display"]
    local execute = (require("godbolt.execute")).execute
    local fuzzy = (require("godbolt.fuzzy")).fuzzy
    local ft = vim.bo.filetype
    local compiler0 = (compiler or M.config[ft].compiler)
    local options
    if M.config[ft] then
      options = vim.deepcopy(M.config[ft].options)
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
      return fuzzy(ft, begin, _end, options, (true == vim.b.godbolt_exec), reuse_3f)
    else
      pre_display(begin, _end, compiler0, options, reuse_3f)
      if vim.b.godbolt_exec then
        return execute(begin, _end, compiler0, options)
      else
        return nil
      end
    end
  else
    return api.nvim_err_writeln("setup function not called")
  end
end
return M
