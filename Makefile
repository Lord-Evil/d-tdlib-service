all:
	#dmd tg.d tdjson.d tdlog.d -L./libtdjson.so -L-rpath=./
	dmd tg.d tdjson.d tdlog.d -c
	cc *.o -o tg -m64 -Xlinker -no_compact_unwind -Xlinker ./libtdjson.dylib -Xlinker -rpath ./ -L/usr/local/opt/dmd/lib -lphobos2 -lpthread -lm