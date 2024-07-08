.PHONY: format clean all
FLAGS = --globals vim --add-macro-path ./fnl/?.fnl --compile
FNL_FILES = $(filter-out fnl/godbolt/macros.fnl,$(wildcard fnl/*.fnl fnl/**/*.fnl))
LUA_FILES = $(patsubst fnl/%.fnl,lua/%.lua,$(FNL_FILES))

all: $(LUA_FILES) plugin/godbolt.lua
lua/%.lua: fnl/%.fnl
	fennel $(FLAGS) $< > $@
plugin/godbolt.lua: plugin/godbolt.fnl
	fennel $(FLAGS) $< > $@

clean:
	rm -f lua/godbolt/* plugin/godbolt.lua
format:
	@./format fnl/godbolt/*
	@./format plugin/godbolt.fnl
