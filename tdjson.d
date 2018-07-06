module tdjson;
import std.string;
import std.json;
import std.stdio;
import std.conv: to;
import std.file;

class TDClient
{
private:
	void * _client;
	bool isAuthorized=false;
public:
	this(){
		_client = td_json_client_create();
		send(`{"@type": "getAuthorizationState"}`);
	}
	void send(string request){
		td_json_client_send(_client, toStringz(request));
	}
	string receive(){
		double timeout=1.0;
		return fromStringz(td_json_client_receive(_client, timeout));
	}
	string execute(string request){
		return fromStringz(td_json_client_execute(_client, toStringz(request)));
	}
	~this(){
		td_json_client_destroy(_client);
	}

	//extra methods
	void loop(){
		while(true)
		{
			string event;
			try
			{
				event=receive();
				if(event==null){
					//writeln("NOTHING");
				}else{
					processEvent(event);
				}
			}catch(Throwable ex){
				writeln("--------ERROR------");
				writeln(event);
				writeln(ex);
			}
		}
	}
	void processEvent(string event){
		JSONValue ev = parseJSON(event);
		switch(ev["@type"].str){
			case "authorizationStateWaitTdlibParameters":

				break;
			case "updateAuthorizationState":
				processAuth(ev["authorization_state"]);
				break;
			case "updateOption":

				break;
			case "updateNewMessage":
				if(ev["message"]["@type"].str=="message"){
					if(ev["message"]["is_outgoing"].type==JSON_TYPE.FALSE){
						//writeln(event);
						//if private
						if(ev["message"]["sender_user_id"].integer==ev["message"]["chat_id"].integer){
							//if incomming
							if(ev["message"]["content"]["@type"].str=="messageText"&&ev["message"]["content"]["text"]["@type"].str=="formattedText"){
								writeln(ev["message"]["chat_id"].integer.to!string~":"~ev["message"]["content"]["text"]["text"].str);
							}
						}
					}
				}
				break;
			case "updateNewChat":

				break;
			case "updateChatTitle":

				break;
			case "updateUser":

				break;
			case "updateUserStatus":

				break;
			case "ok":

				break;

			default:
				//writeln(event);
				break;
		}
	}
	void processAuth(JSONValue ev){
		//authorization_state
/*		authorizationStateReady
	authorizationStateClosing
	authorizationStateClosed
	authorizationStateWaitCode
	authorizationStateWaitPassword
	authorizationStateWaitPhoneNumber
	authorizationStateWaitEncryptionKey
	authorizationStateWaitTdlibParameters*/
		switch(ev["@type"].str){
			case "authorizationStateWaitTdlibParameters":
				writeln(">>Please, enter profile name");
				string profilename=stdin.readln().strip();
				JSONValue parameters = parseJSON(readText("config.json"));
				parameters["database_directory"]="data/"~profilename;
				send(`{"@type": "setTdlibParameters", "parameters":`~parameters.toString()~`}`);
				send(`{"@type": "getAuthorizationState"}`);
				break;
			case "authorizationStateWaitEncryptionKey":
				send(`{"@type": "checkDatabaseEncryptionKey"}`);
				send(`{"@type": "getAuthorizationState"}`);
				break;
			case "authorizationStateWaitPhoneNumber":
				writeln(">>Please, enter your phone number");
				string phone=stdin.readln().strip().replace("+","");
				send(`{"@type": "setAuthenticationPhoneNumber", "phone_number":"`~phone~`"}`);
				send(`{"@type": "getAuthorizationState"}`);
				break;
			case "authorizationStateWaitCode":
				writeln(">>Please, enter the code");
				string code=stdin.readln().strip();
				send(`{"@type": "checkAuthenticationCode", "code":"`~code~`"}`);
				send(`{"@type": "getAuthorizationState"}`);
				break;
			case "authorizationStateReady":
				writeln("READY");
				isAuthorized=true;
				break;
			default:
				writeln(ev);
				break;
		}
	}
}

extern (C) {
	void *td_json_client_create();
	void td_json_client_send(void *client, in char* request);
	immutable(char) * td_json_client_receive(void *client, double timeout);
	immutable(char) * td_json_client_execute(void *client, in char * request);
	void td_json_client_destroy(void *client);
}
