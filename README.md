# godbolt.nvim

Display assembly for the current buffer or visual selection from https://godbolt.org

Requires neovim 0.6 and `curl`

## Setup
You need to call the setup function in your config. Calling it without arguments uses these default values:

```lua
require("godbolt").setup({
    c = { compiler = "cg112", options = {} },
    cpp = { compiler = "g112", options = {} },
    rust = { compiler = "r1560", options = {} }
    -- any_additional_filetype = { compiler = ..., options = ... }
})
```

If your neovim config is in lua then place this snippet in your config directly, otherwise place it inside a lua block like so:
```vim
lua << EOF
    require("godbolt").setup({
        ...
    })
EOF
```

`options` is a table corresponding to the `options` field in the [schema](https://github.com/compiler-explorer/compiler-explorer/blob/main/docs/API.md#post-apicompilercompiler-idcompile---perform-a-compilation). For example, if you want to add compiler flags then you need to set it to `{ userArguments = "-Wall -O2" }`.

You can get the list of compiler ids by visiting or `curl`ing `https://godbolt.org/api/compilers/<language>`

(Note: use `c++`, not `cpp` for C++)


## Usage

 - To use the default/setup compiler for the entire buffer:

  `:Godbolt`
 - To use the default/setup compiler for a visual selection: Select the function(s) you want and

  `:'<,'>Godbolt`
 - To use a custom compiler with flags for the entire buffer:

  `:GodboltCompiler <compiler> <flags>`

   **NOTE**:
   1) This will not use the options in your config! For example, if you want to use third-party libraries like boost and add compiler flags, you should set this up in your config instead, as described in the setup section above.

   2) You need to escape the options appropriately here, like `:GodboltCompiler g112 -Wall\ -O2`
 - Similarly, to use a custom compiler with flags for a visual selection: Select the function you want and

  `:'<,'>GodboltCompiler <compiler> <flags>`

## Demo
https://user-images.githubusercontent.com/36493671/142733190-433f8057-6be2-4012-a235-435f30c8a012.mp4

## TODO
 - [ ] Telescope for selecting custom compiler.
 - [ ] Update default compilers using Github Actions.
