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
	/*
	auto t = runTask(toDelegate(&test));
	writeln("Main");
	t.join();
	*/

	TDLog.setPath("tg.log");
	TDLog.setCallback(&errorHandler);
	TDLog.setLevel(2);

	TDClient client=new TDClient();
	client.loop();

}