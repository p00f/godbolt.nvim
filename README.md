![alt text](https://user-images.githubusercontent.com/36493671/143468676-089f623f-f913-4af6-bc78-dbfaa1e92c69.png)


# godbolt.nvim

Display assembly for the current buffer or visual selection from https://godbolt.org (or any godbolt instance)

Requires neovim 0.6 and curl

## Setup
You can call the setup function in your config to override these default values:

```lua
require("godbolt").setup({
    languages = {
        cpp = { compiler = "g122", options = {} },
        c = { compiler = "cg122", options = {} },
        rust = { compiler = "r1650", options = {} },
        -- any_additional_filetype = { compiler = ..., options = ... },
    },
    auto_cleanup = true, -- remove highlights and autocommands on buffer close
    highlight = {
        cursor = "Visual", -- `cursor = false` to disable
        -- values in this table can be:
        -- 1. existing highlight group
        -- 2. hex color string starting with #
        static = { "#222222", "#333333", "#444444", "#555555", "#444444", "#333333" },
        -- `static = false` to disable
    },
    -- `highlight = false` to disable highlights
    quickfix = {
        enable = false, -- whether to populate the quickfix list in case of errors
        auto_open = false -- whether to open the quickfix list in case of errors
    },
    url = "https://godbolt.org" -- can be changed to a different godbolt instance
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

  `:Godbolt` and type in compiler flags in the prompt if needed
 - To use the default/setup compiler for a visual selection: Select the function(s) you want and

  `:'<,'>Godbolt`
 - To use a custom compiler for the entire buffer:

  `:GodboltCompiler <compiler>`.

 - Similarly, to use a custom compiler for a visual selection: Select the function you want and

  `:'<,'>GodboltCompiler <compiler>`.

 - Adding a bang (`!`) to either command (`:Godbolt!`, `:GodboltCompiler!`) will reuse the last assembly window for the current source buffer.

### Fuzzy finder integration

If in `:GodboltCompiler <compiler>` or `:'<,'>GodboltCompiler <compiler>`, `<compiler>` is `telescope`, `fzf`, `skim` or `fzy`, you can choose the compiler using [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), [fzf](https://github.com/junegunn/fzf), [skim](https://github.com/lotabout/skim) or [fzy](https://github.com/jhawthorn/fzy) + [nvim-fzy](https://github.com/mfussenegger/nvim-fzy) respectively.

### Quickfix
Set `quickfix.enable = true` as described above to populate the quickfix in case of errors.
If `quickfix.auto_open` is true, a quickfix list will automatically open if the compiler outputs errors. Otherwise you can manually `:copen`

Screencast:

[![asciicast](https://asciinema.org/a/ChS7h6JM2vrco2Y71tVKb4tg3.svg)](https://asciinema.org/a/ChS7h6JM2vrco2Y71tVKb4tg3)

## Demo
[![asciicast](https://asciinema.org/a/451832.svg)](https://asciinema.org/a/451832)
