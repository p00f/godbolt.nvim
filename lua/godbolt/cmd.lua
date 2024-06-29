local function build_cmd(compiler, text, options, exec_asm_3f)
  local json = vim.json.encode({source = text, options = options})
  local config = require("godbolt").config
  local file = io.open(string.format("godbolt_request_%s.json", exec_asm_3f), "w")
  file:write(json)
  io.close(file)
  return string.format(("curl %s/api/compiler/\"%s\"/compile" .. " --data-binary @godbolt_request_%s.json" .. " --header \"Accept: application/json\"" .. " --header \"Content-Type: application/json\"" .. " --output godbolt_response_%s.json"), config.url, compiler, exec_asm_3f, exec_asm_3f)
end
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
local function godbolt(begin, _end, reuse_3f, compiler)
  local pre_display = require("godbolt.assembly")["pre-display"]
  local execute = require("godbolt.execute").execute
  local fuzzy = require("godbolt.fuzzy").fuzzy
  local ft = vim.bo.filetype
  local config = require("godbolt").config
  local compiler0 = (compiler or config.languages[ft].compiler)
  local options
  if config.languages[ft] then
    options = vim.deepcopy(config.languages[ft].options)
  else
    options = {}
  end
  if (config.highlights and not vim.tbl_isempty(config.highlights) and (config.highlights[1] ~= "Godbolt1")) then
    print("SETUP HIGHLIGHTS")
    config.highlights = setup_highlights(config.highlights)
  else
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
      return execute(begin, _end, compiler0, options, reuse_3f)
    else
      return nil
    end
  end
end
return {["build-cmd"] = build_cmd, godbolt = godbolt}
