# godbolt.nvim

Display assembly for the current buffer or visual selection from https://godbolt.org

## Setup
You need to call the setup function in your config. Calling it without arguments uses these default values:

```lua
require("godbolt").setup({
    c = { compiler = "cg112", options = nil },
    cpp = { compiler = "g112", options = nil },
    rust = { compiler = "r1560", options = nil }
    -- any_additional_filetype = { compiler = ..., options = ... }
})
```
`options` is a string, like `"-Wall -Wextra -pedantic"`.

You can get the list of compiler ids by visiting or `curl`ing `https://godbolt.org/api/compilers/<language>`

(Note: use `c++`, not `cpp` for C++)


## Usage

 - To use the default/setup compiler for the entire buffer:

  `:Godbolt`
 - To use the default/setup compiler for a visual selection: Select the function you want and
 
  `:'<,'>Godbolt`
 - To use a custom compiler with options for the entire buffer:

  `:GodboltCompiler <compiler> <options>`
  
   You need to escape the options appropriately here, like `:GodboltCompiler g112 -Wall\ -O2`
 - Similarly, to use a custom compiler with options for a visual selection: Select the function you want and

  `:'<,'>GodboltCompiler <compiler> <options>`

## Demo
https://user-images.githubusercontent.com/36493671/142684304-68e606a2-faa5-4aa1-ab16-09f509f661ce.mp4

## TODO
 - [ ] Telescope for selecting custom compiler.
 - [ ] Update default compilers using Github Actions.
