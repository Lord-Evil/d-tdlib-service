import std.stdio;
import tdjson;
import tdlog;

extern (C) void errorHandler(string message){
	writeln("Error: "~message);
}

void main(){
	TDLog.setPath("tg.log");
	TDLog.setCallback(&errorHandler);
	TDLog.setLevel(2);

	TDClient client=new TDClient();
	client.loop();

}