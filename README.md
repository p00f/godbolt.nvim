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

`options` is a table corresponding to the `options` field in the [schema](https://github.com/compiler-explorer/compiler-explorer/blob/main/docs/API.md#post-apicompilercompiler-idcompile---perform-a-compilation). For example:

 - If you want to add compiler flags then you need to set it to `{ userArguments = "-Wall -O2" }`
 - If you want to use boost then you need to set it to `{ userArguments = "-I /opt/compiler-explorer/libs/boost_1_77_0", libraries = { id = "boost", version = "1.77.0" } }` and so on. `-I /opt/compiler-explorer/libs/boost_1_77_0` was for including boost, you can get the path of the library by `curl`ing or visiting `https://godbolt.org/api/libraries/c++`

You can get the list of compiler ids by visiting or `curl`ing `https://godbolt.org/api/compilers/<language>` (or using the fuzzy finders mentioned) and the list of libraries by `curl`ing or visiting `https://godbolt.org/api/libraries/<language>`. For more info, see https://github.com/compiler-explorer/compiler-explorer/blob/main/docs/API.md

(Note: use `c++`, not `cpp` for C++)


## Usage

  Setting `b:godbolt_exec` to true will execute the code in addition to displaying assembly and display the output/error in the message area.

 - To use the default/setup compiler for the entire buffer:

  `:Godbolt`
 - To use the default/setup compiler for a visual selection: Select the function(s) you want and

  `:'<,'>Godbolt`
 - To use a custom compiler with flags for the entire buffer:

  `:GodboltCompiler <compiler>` and type in your flags in the prompt.

 - Similarly, to use a custom compiler with flags for a visual selection: Select the function you want and

  `:'<,'>GodboltCompiler <compiler>` and type in your flags in the prompt.

### Fuzzy finder integration

If in `:GodboltCompiler <compiler>` or `:'<,'>GodboltCompiler <compiler>`, `<compiler>` is `telescope`, `fzf`, `skim` or `fzy`, you can choose the compiler using [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), [fzf](https://github.com/junegunn/fzf), [skim](https://github.com/lotabout/skim) or [fzy](https://github.com/jhawthorn/fzy) + [nvim-fzy](https://github.com/mfussenegger/nvim-fzy) respectively.

## Demo
https://user-images.githubusercontent.com/36493671/143026157-d74eaa39-6768-4f7a-8e36-f5395464c3ec.mp4


## TODO
 - [ ] Update default compilers using Github Actions.
