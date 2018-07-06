all:
	dmd tg.d tdjson.d tdlog.d -L./libtdjson.so -L./lib/libvibe_core.so -Iinclude -L-rpath=./
mac:
	dmd tg.d tdjson.d tdlog.d -c -Iinclude
	cc *.o -o tg -m64 -Xlinker -no_compact_unwind -Xlinker ./libtdjson.dylib .libMac/libvibe_core.a .liibMac/libeventcore.a .libMac/libstdx-allocator.a .libMac/libtaggedalgebraic.a -Xlinker -rpath ./ -L/usr/local/opt/dmd/lib -lphobos2 -lpthread -lm
