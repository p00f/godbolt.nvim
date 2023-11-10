.PHONY: format clean all
FNL_FILES = $(filter-out fnl/godbolt/macros.fnl,$(wildcard fnl/godbolt/*.fnl))
LUA_FILES = $(subst fnl,lua,$(FNL_FILES))

all: $(LUA_FILES) plugin/godbolt.lua
lua/%.lua: fnl/%.fnl
	fennel --globals vim --add-macro-path ./fnl/?.fnl --compile $< > $@
plugin/godbolt.lua: plugin/godbolt.fnl
	fennel --globals vim --add-macro-path ./fnl/?.fnl --compile $< > $@

clean:
	rm -f lua/godbolt/* plugin/godbolt.lua
format:
	@./format fnl/godbolt/*
	@./format plugin/godbolt.fnl
