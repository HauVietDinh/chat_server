%% chat_room.erl
%% Gen_server implementing a chat room with ETS message storage and
%% alive-processes.

-module(chat_room).
-behaviour(gen_server).
-include("chat.hrl").

%% API
-export([start_link/1]).
-export([stop/1,
         users/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

%% how often the alive-process pings the user
-define(ALIVE_CHECK_MS, 5000).

%% Public API
start_link(RoomId) ->
    case global:whereis_name(RoomId) of
        undefined ->
            gen_server:start_link({global, RoomId}, ?MODULE, RoomId, []);
        _ ->
            io:format("Room ~p already exists~n", [RoomId])
    end.

%% Start the chat room and register it globally as {global, RoomId}
stop(RoomId) ->
    gen_server:call({global, RoomId}, stop).

users(RoomId) ->
    gen_server:call({global, RoomId}, get_users).

%% gen_server callbacks
init(RoomId) ->
    process_flag(trap_exit, true),
    {ok, TableName} = integer_to_atom(RoomId),
    ets:new(TableName, [ordered_set, public, named_table, {keypos, 2}]),
    %% create ETS table for messages
    State = #{room_id => RoomId,
              msg_table => TableName,
              users => #{}, % map UserName => UserPid
              alive_map => #{} %UserName => AlivePid
             },
    {ok, State}.

handle_call(stop, _From, State) ->
    {stop, normal, ok, State};

handle_call({join, UserName, UserPid}, _From,
            #{users := Users, alive_map := AliveMap,
              msg_table := TableName}=State) ->
    case maps:is_key(UserName, Users) of
        true ->
            {reply, {error, username_taken}, State};
        false ->
            %% store user
            NewUsers = Users#{UserName => UserPid},
            %% spawn alive checker
            RoomPid = self(),
            AlivePid = spawn_link(fun() ->
                                        alive_loop(RoomPid, UserName, UserPid)
                                  end),
            %% track alive pid in process dictionary (or additional map)
            NewAliveMap = AliveMap#{UserName => AlivePid},
            NewState = State#{users => NewUsers, alive_map => NewAliveMap},
            %% notify other users
            broadcast_join(UserName, NewUsers),
            %% send history to new user
            send_history(TableName, UserPid),
            {reply, ok, NewState}
    end;

handle_call({leave, UserName}, _From, #{users := Users,
                                        alive_map := AliveMap}=State) ->
    %% stop alive process
    case AliveMap of
        #{UserName := AlivePid} ->
            exit(AlivePid, kill),
            ok;
        _ -> ok
    end,
    RestUsers = maps:remove(UserName, Users),
    broadcast_leave(UserName, RestUsers),
    NewState = State#{users => RestUsers},
    {reply, ok, NewState};

handle_call({send, UserName, Text}, _From, #{room_id := RoomId,
                                             msg_table := TableName}=State) ->
    Users = maps:get(users, State),
    case maps:find(UserName, Users) of
        error ->
            {reply, {error, not_in_room}, State};
        {ok, _UserPid} ->
            TimeMs =
                calendar:system_time_to_rfc3339(erlang:system_time(second)),
            Msg = #msg{room_id = RoomId, username = UserName, time_ms = TimeMs,
                       text = Text},
            ets:insert(TableName, Msg),
            %% broadcast to everyone
            broadcast_message(Msg, Users),
            {reply, ok, State}
    end;

handle_call(get_users, _From, State) ->
    Users = maps:get(users, State),
    {reply, maps:keys(Users), State};

handle_call(_Req, _From, State) ->
    {reply, {error, bad_request}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({user_down, UserName}, #{users := Users,
                                     alive_map := AliveMap}=State) ->
    %% Alive process told us user didn't respond. Remove user and notify others.
    case maps:take(UserName, Users) of
        {_UserPid, RestUsers} ->
            AliveMap2 = maps:remove(UserName, AliveMap),
            broadcast_leave(UserName, RestUsers),
            {noreply, State#{users => RestUsers, alive_map => AliveMap2}};
        error ->
            {noreply, State}
    end;

handle_info({'EXIT', _Pid, _Reason}, State) ->
    %% ignore for now; alive processes are linked so room will receive exit
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, #{msg_table := TableName}) ->
    %% cleanup ETS table if needed
    try ets:delete(TableName) catch _:_ -> ok end,
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Helper functions

broadcast_message(Msg, Users) ->
    lists:foreach(fun({_Name, Pid}) ->
                          gen_server:cast(Pid, {deliver, Msg})
                  end, maps:to_list(Users)).

broadcast_join(NewUser, Users) ->
    Time = calendar:system_time_to_rfc3339(erlang:system_time(second)),
    Notification = {notice, {join, NewUser, Time}},
    lists:foreach(fun({_Name, Pid}) ->
                          gen_server:cast(Pid, Notification)
                  end, maps:to_list(Users)).

broadcast_leave(User, Users) ->
    Time = calendar:system_time_to_rfc3339(erlang:system_time(second)),
    Notification = {notice, {leave, User, Time}},
    lists:foreach(fun({_Name, Pid}) ->
                          gen_server:cast(Pid, Notification)
                  end, maps:to_list(Users)).

%% deliver all message to the newly joined user
send_history(TableName, UserPid) ->
    Msgs = ets:tab2list(TableName),
    gen_server:cast(UserPid, {history, Msgs}).

%% Alive-process: pings the user gen_server periodically;
%% if user doesn't reply, notify room.
alive_loop(RoomPid, UserName, UserPid) ->
    %% loop with ping interval
    timer:sleep(?ALIVE_CHECK_MS),
    %% synchronous call to user to check liveness; timeout is 1/2 of interval
    Alive = catch gen_server:call(UserPid, ping, ?ALIVE_CHECK_MS div 2),
    case Alive of
        pong ->
            alive_loop(RoomPid, UserName, UserPid);
        {'EXIT', _} ->
            RoomPid ! {user_down, UserName},
            exit(normal);
        {'timeout', _} ->
            RoomPid ! {user_down, UserName},
            exit(normal);
        _Other ->
            %% treat as failure
            RoomPid ! {user_down, UserName},
            exit(normal)
    end.

integer_to_atom(Int) when is_integer(Int) ->
    {ok, list_to_atom(integer_to_list(Int))};
integer_to_atom(_) ->
    error.
