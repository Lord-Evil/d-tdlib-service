import std.stdio;
import std.functional : toDelegate;
import std.conv: to;
import core.time;
import vibe.core.core;
import vibe.http.server;

import tdjson;
import tdlog;

alias void function(int) sighandler_t;
extern (C) sighandler_t signal(int signum, sighandler_t handler);

void shutDown(int i){
	writeln("\nSignal caught! "~i.to!string~"\nShutting down!");
	sleep(1.msecs);
	client.destroy();
	sleep(500.msecs);
}

void errorHandler(string message){
	writeln("Error: "~message);
}

TDClient client;
void main(){
	disableDefaultSignalHandlers();
	signal(2,&shutDown);
	signal(15,&shutDown);

	TDLog.setPath("tg.log");
	TDLog.setCallback(&errorHandler);
	TDLog.setLevel(2);
	client=new TDClient();
	client.loop();

	runApplication();
}