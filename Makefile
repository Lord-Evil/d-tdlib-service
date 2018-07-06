all:
	dmd tg.d tdjson.d tdlog.d  ./lib/libstdx-allocator.a -L./lib/libtdjson.so -L./lib/libvibe_core.so -L./lib/libvibe_http.so -L./lib/libvibe_stream.so -L./lib/libvibe_crypto.so -L./lib/libvibe_utils.so -L./lib/libvibe_inet.so -L./lib/libvibe_data.so -L./lib/libvibe_tls.so -L./lib/libvibe_textfilter.so -L./lib/libvibe_internal.so -L./lib/libevent-2.1.so.5 -Iinclude -L-rpath=./lib -L-s -version=Have_vibe_core -version=VibeLibeventDriver

mac:
	
	dmd tg.d tdjson.d tdlog.d -c -Iinclude -version=Have_vibe_core
	cc *.o -o tg -m64 -Xlinker -no_compact_unwind -Xlinker ./lib/libtdjson.dylib .libMac/libvibe_core.a .liibMac/libeventcore.a .libMac/libstdx-allocator.a .libMac/libtaggedalgebraic.a -Xlinker -rpath ./ -L/usr/local/opt/dmd/lib -lphobos2 -lpthread -lm
