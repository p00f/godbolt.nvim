SHELL := fish
default:
	fennel --globals vim --compile fnl/godbolt/init.fnl > lua/godbolt/init.lua
	fennel --globals vim,gb-exports --compile fnl/godbolt/assembly.fnl > lua/godbolt/assembly.lua
	fennel --globals vim --compile fnl/godbolt/execute.fnl > lua/godbolt/execute.lua
	fennel --globals vim --compile fnl/godbolt/telescope.fnl > lua/godbolt/telescope.lua
	fennel --globals vim --compile fnl/godbolt/fzf.fnl > lua/godbolt/fzf.lua
clean:
	rm lua/godbolt/*
