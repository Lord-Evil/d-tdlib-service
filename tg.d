import std.stdio;
import vibe.core.core;
import std.functional : toDelegate;

import tdjson;
import tdlog;

void errorHandler(string message){
	writeln("Error: "~message);
}

void main(){
	TDLog.setPath("tg.log");
	TDLog.setCallback(&errorHandler);
	TDLog.setLevel(2);
	TDClient client=new TDClient();
	client.loop();

	runApplication();
}