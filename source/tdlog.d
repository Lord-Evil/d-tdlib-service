module tdlog;
import std.string;

static class TDLog
{
	static bool setPath(string path){
		return td_set_log_file_path(toStringz(path))==1;
	}
	static void setMaxSize(ulong size){
		td_set_log_max_file_size(size);
	}
	static void setLevel(int level){
		td_set_log_verbosity_level(level);
	}
	static void function(string message) callback;
	static void setCallback(void function(string message) c){
		callback = c;
		extern (C) void cb(char * m){
			callback(cast(string)fromStringz(m));
		}
		td_set_log_fatal_error_callback(&cb);
	}
}
extern (C) {
	int td_set_log_file_path(in char * file_path);
	void td_set_log_max_file_size(ulong max_file_size);
	void td_set_log_verbosity_level(int new_verbosity_level);
	alias td_log_fatal_error_callback_ptr = void function(char * error_message);
	void td_set_log_fatal_error_callback(td_log_fatal_error_callback_ptr callback);
}