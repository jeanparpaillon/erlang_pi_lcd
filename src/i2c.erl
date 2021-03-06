-module(i2c).
-behaviour(gen_server).
-export([code_change/3, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).
-export([start_link/1, init/1, write_list/2, write_word/2]).

-define(CMD_WRITE_BLOCK_DATA, 3).
-define(CMD_OPEN, 4).

start_link(Device) ->
	Dir = code:priv_dir(lcd_app),
	case erl_ddll:load_driver(Dir, i2c_drv) of
		ok -> ok;
		{error, already_loaded} -> ok;
		{error, Message} -> exit(erl_ddll:format_error(Message))
	end,
	gen_server:start_link({local, ?MODULE}, ?MODULE, [Device], []).

init(Device) ->
	Port = open_port({spawn_driver, i2c_drv}, [use_stdio, binary]),
	port_control(Port, ?CMD_OPEN, Device),
	{ ok, Port }.

handle_call({write_list, Register, Value}, _From, State) ->
	port_control(State, ?CMD_WRITE_BLOCK_DATA, [Register, Value]),
	{reply, ok, State}.

handle_cast(_Request, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.	

write_list(Register, Value) ->
	gen_server:call(?MODULE, {write_list, Register, Value}).

word_to_byte_array(Word) ->
	[Word band 16#ff, Word bsr 8].

write_word(Register, W) ->
	write_list(Register, word_to_byte_array(W)).
