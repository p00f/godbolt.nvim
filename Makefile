default:
	fennel --globals vim --compile fnl/godbolt.fnl > lua/godbolt.lua
	fennel --globals vim --compile fnl/godbolt/telescope.fnl > lua/godbolt/telescope.lua
clean:
	rm lua/godbolt.lua
	rm lua/godbolt/telescope.lua
