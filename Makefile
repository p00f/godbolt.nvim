SHELL := fish
.PHONY: format
default:
	fennel --globals vim --add-macro-path fnl/godbolt/macros.fnl --compile fnl/godbolt/init.fnl > lua/godbolt/init.lua
	fennel --globals vim --add-macro-path fnl/godbolt/macros.fnl --compile fnl/godbolt/cmd.fnl > lua/godbolt/cmd.lua
	fennel --globals vim --add-macro-path fnl/godbolt/macros.fnl --compile fnl/godbolt/assembly.fnl > lua/godbolt/assembly.lua
	fennel --globals vim --add-macro-path fnl/godbolt/macros.fnl --compile fnl/godbolt/execute.fnl > lua/godbolt/execute.lua
	fennel --globals vim --add-macro-path fnl/godbolt/macros.fnl --compile fnl/godbolt/fuzzy.fnl > lua/godbolt/fuzzy.lua
	fennel --globals vim --add-macro-path fnl/godbolt/macros.fnl --compile plugin/godbolt.fnl > plugin/godbolt.lua
clean:
	rm lua/godbolt/*
format:
	@./format fnl/godbolt/*
	@./format fnl/macros.fnl
