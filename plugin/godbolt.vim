command -nargs=* -range=% Godbolt lua require("godbolt").godbolt(<line1>, <line2>)
command -nargs=+ -range=% GodboltCompiler lua require("godbolt").godbolt(<line1>, <line2>, <f-args>)
