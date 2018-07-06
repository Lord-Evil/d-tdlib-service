all:
	dmd tg.d tdjson.d tdlog.d -L./libtdjson.so -L-rpath=./
mac:
	dmd tg.d tdjson.d tdlog.d -c -Iinclude
	cc *.o -o tg -m64 -Xlinker -no_compact_unwind -Xlinker ./libtdjson.dylib ./libvibe_core.a ./libeventcore.a ./libstdx-allocator.a ./libtaggedalgebraic.a	-Xlinker -rpath ./ -L/usr/local/opt/dmd/lib -lphobos2 -lpthread -lm
