%% chat_user.erl
%% A gen_server representing a user running in its own shell/node.
%% The user prints received messages to its shell.

-module(chat_user).
-behaviour(gen_server).
-include("chat.hrl").

-export([start_link/1, join/1, chat/1, exit_room/0]).
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {username, room_id}).

%%% API
start_link(UserName) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, UserName, []).

join(RoomId) ->
    gen_server:call(?MODULE, {join, RoomId}).

chat(Text) ->
    %% send chat to current room
    gen_server:call(?MODULE, {chat, Text}).

exit_room() ->
    gen_server:call(?MODULE, leave).

%%%% gen_server callbacks

init(UserName) ->
    case find_server_node() of
        {ok, ServerNode} ->
            case net_adm:ping(ServerNode) of
                pong ->
                    ok = global:sync([ServerNode]),
                    process_flag(trap_exit, true),
                    {ok, #state{username = UserName, room_id = undefined}};
                _ ->
                    {stop, cannot_connect_server}
            end;
        Error -> {stop, Error}
    end.

%% internal helpers

handle_call({join, RoomId}, _From, #state{username=UserName,
                                          room_id=undefined}=State) ->
    case global:whereis_name(RoomId) of
        undefined ->
            {reply, {error, room_not_found}, State};
        RoomPid ->
            case gen_server:call(RoomPid, {join, UserName, self()}) of
                ok ->
                    io:format("~s joined room ~p~n", [UserName, RoomId]),
                    {reply, ok, State#state{room_id = RoomId}};
                Error ->
                    {reply, Error, State}
            end
    end;
handle_call({join, _RoomId}, _From, #state{room_id=RoomId}=State) ->
    {reply, {error, already_in_room, RoomId}, State};

handle_call({chat, _Text}, _From, #state{room_id=undefined}=State) ->
    {reply, {error, not_in_room}, State};
handle_call({chat, Text}, _From, #state{username=UserName,
                                        room_id=RoomId}=State) ->
    %% send to room via global find
    case global:whereis_name(RoomId) of
        undefined ->
            {reply, {error, room_gone}, State};
        RoomPid ->
            gen_server:call(RoomPid, {send, UserName, Text}),
            {reply, ok, State}
    end;

handle_call(leave, _From, #state{room_id=undefined}=State) ->
    {reply, {error, not_in_room}, State};
handle_call(leave, _From, #state{room_id=RoomId,
                                 username=UserName}=State) ->
    case global:whereis_name(RoomId) of
        undefined ->
            {reply, ok, State#state{room_id = undefined}};
        RoomPid ->
            gen_server:call(RoomPid, {leave, UserName}),
            {reply, ok, State#state{room_id = undefined}}
    end;

%% ping from alive checker
handle_call(ping, _From, State) ->
    {reply, pong, State};

handle_call(_Other, _From, State) ->
    {reply, {error, bad_request}, State}.

handle_cast({deliver, Msg}, State) ->
    print_msg(Msg),
    {noreply, State};

handle_cast({history, Msgs}, State) ->
    [print_msg(Msg) || Msg <- Msgs],
    {noreply, State};

handle_cast({notice, {join, NewUser, T}}, State) ->
    io:format("** ~p joined at ~p~n", [NewUser, T]),
    {noreply, State};

handle_cast({notice, {leave, User, T}}, State) ->
    io:format("** ~p left at ~p~n", [User, T]),
    {noreply, State};

handle_cast(_Other, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_R, _S) ->
    ok.

code_change(_Old, S, _Extra) ->
    {ok, S}.

find_server_node() ->
    case file:read_file(?SERVER_NODE_FILE) of
        {ok, Bin} ->
            NodeName = binary_to_list(string:trim(Bin)),
            {ok, list_to_atom(NodeName)};
        _ ->
            {error, no_server}
    end.

print_msg(#msg{room_id=RoomId, username=From, time_ms=Time, text=Text}) ->
    io:format("[Room ~p]- ~p [~p]: ~s~n", [RoomId, From, Time, Text]).
