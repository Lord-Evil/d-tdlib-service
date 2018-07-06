import std.stdio;
import vibe.core.core;
import std.functional : toDelegate;

import tdjson;
import tdlog;

extern (C) void errorHandler(string message){
	writeln("Error: "~message);
}

void test(){
	writeln("Tesing");
}

void main(){
	
/*	auto t = runTask(toDelegate(&test));
	auto t2 = runTask({writeln(2);});
	writeln("Main");
	t.join();
	t2.join();
	return;*/

	TDLog.setPath("tg.log");
	TDLog.setCallback(&errorHandler);
	TDLog.setLevel(2);

	TDClient client=new TDClient();
	auto loop = runTask(&client.loop);
	loop.join();
}