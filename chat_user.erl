%% chat_user.erl
%% A gen_server representing a user running in its own shell/node.
%% The user prints received messages to its shell.

-module(chat_user).
-behaviour(gen_server).
-include("chat.hrl").

-export([start_link/1, join/2, chat/1, exit_room/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {username, room_id}).

%%% API
start_link(UserName) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, UserName, []).

join(UserName, RoomId) ->
    %% start local user server if not started
    case whereis(?MODULE) of
        undefined ->
            {ok, Pid} = start_link(UserName),
            do_join(Pid, RoomId, UserName);
        Pid ->
            do_join(Pid, RoomId, UserName)
    end.

chat(Text) ->
    %% send chat to current room
    gen_server:call(?MODULE, {chat, Text}).

exit_room() ->
    gen_server:call(?MODULE, leave).

%% internal helpers
do_join(Pid, RoomId, UserName) ->
    %% locate room via global name
    % net_adm:ping(?CHAT_SERVER),
    % timer:sleep(500),
    % io:format("Wating for connect..~n"),
    {ok, ChatRoom} = find_room_node(RoomId),
    pong = net_adm:ping(ChatRoom),
    ok = global:sync([ChatRoom]),
    case global:whereis_name(RoomId) of
        undefined ->
            {error, room_not_found};
        RoomPid ->
            case gen_server:call(RoomPid, {join, UserName, Pid}) of
                {ok, _Count} ->
                    gen_server:call(Pid, {joined, RoomId, RoomPid});
                Error -> Error
            end
    end.

%%%% gen_server callbacks

init(UserName) ->
    process_flag(trap_exit, true),
    State = #state{username = UserName, room_id = undefined},
    io:format("User ~p started on pid ~p~n", [UserName, self()]),
    {ok, State}.

handle_call({joined, RoomId, _RoomPid}, _From, State) ->
    NewState = State#state{room_id = RoomId},
    io:format("~s joined room ~p~n", [State#state.username, RoomId]),
    {reply, ok, NewState};

handle_call({chat, Text}, _From, State = #state{username = UserName, room_id = undefined}) ->
    {reply, {error, not_in_room}, State};
handle_call({chat, Text}, _From, State = #state{username = UserName, room_id = RoomId}) ->
    %% send to room via global find
    case global:whereis_name(RoomId) of
        undefined -> {reply, {error, room_gone}, State};
        RoomPid ->
            gen_server:call(RoomPid, {send, UserName, Text}),
            {reply, ok, State}
    end;

handle_call(leave, _From, State = #state{room_id = undefined}) ->
    {reply, {error, not_in_room}, State};
handle_call(leave, _From, State = #state{room_id = RoomId, username = UserName}) ->
    case global:whereis_name(RoomId) of
        undefined ->
            NewState = State#state{room_id = undefined},
            {reply, ok, NewState};
        RoomPid ->
            gen_server:call(RoomPid, {leave, UserName}),
            NewState = State#state{room_id = undefined},
            {reply, ok, NewState}
    end;

%% ping from alive checker
handle_call(ping, _From, State) ->
    {reply, pong, State};

handle_call(_Other, _From, State) ->
    {reply, {error, bad_request}, State}.

handle_cast({deliver, Msg = #msg{username=From, time_ms=Time, text=Text}}, State) ->
    io:format("~p [~p]: ~s~n", [From, Time, Text]),
    {noreply, State};

handle_cast({history, Msg}, State) ->
    io:format("History: ~p~n", [Msg]),
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


find_room_node(RoomId) ->
    case file:read_file(?ROOM_NODE_FILE) of
        {ok, Bin} ->
            Lines = string:split(binary_to_list(Bin), "\n", all),
            find_in_lines(RoomId, Lines);
        _ ->
            {error, no_registry}
    end.

find_in_lines(_RoomId, []) ->
    {error, room_not_found};
find_in_lines(RoomId, [Line | Rest]) ->
    case string:tokens(Line, " ") of
        [RoomIdStr, NodeStr] ->
            case list_to_integer(RoomIdStr) of
                RoomId ->
                    {ok, list_to_atom(NodeStr)};
                _ ->
                    find_in_lines(RoomId, Rest)
            end;
        _ ->
            find_in_lines(RoomId, Rest)
    end.
