function s:complete(_a, _b, _c)
    return ['fzf', 'fzy', 'skim', 'telescope']
endfunction

command -bang -nargs=0 -range=% Godbolt lua require("godbolt.cmd").godbolt(<line1>, <line2>, '<bang>' == '!')
command -bang -nargs=1 -range=% -complete=customlist,s:complete GodboltCompiler lua require("godbolt.cmd").godbolt(<line1>, <line2>, '<bang>' == '!', <f-args>)

if get(g:, 'godbolt_loaded', 0) != 1
    let g:godbolt_loaded = 1
lua << EOF
    _G.__godbolt_map = {}
    _G.__godbolt_nsid = vim.api.nvim_create_namespace("godbolt")
EOF
endif
