run:
	zig build && ./zig-out/bin/zgram
clc:
	rm -rf /home/admin/.cache/zls/
	rm -rf /home/admin/.cache/zig/
	rm -rf zig-cache
tf:
	cd telegraf; bun run .	
