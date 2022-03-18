function s:complete(_a, _b, _c)
    return ['fzf', 'fzy', 'skim', 'telescope']
endfunction

command -bang -nargs=0 -range=% Godbolt lua require("godbolt").godbolt(<line1>, <line2>, '<bang>' == '!')
command -bang -nargs=1 -range=% -complete=customlist,s:complete GodboltCompiler lua require("godbolt").godbolt(<line1>, <line2>, '<bang>' == '!', <f-args>)

if get(g:, 'godbolt_loaded', 0) != 1
    lua require("godbolt.assembly").init()
    let g:godbolt_loaded = 1
endif
