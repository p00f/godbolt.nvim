default:
	fennel --globals vim --compile fnl/godbolt.fnl > lua/godbolt.lua
clean:
	rm lua/godbolt.lua
