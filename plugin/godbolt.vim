command -nargs=* -range=% Godbolt lua require("godbolt")["pre-display"](<line1>, <line2>)
command -nargs=+ -range=% GodboltCompiler lua require("godbolt").display(<line1>, <line2>, <f-args>)
