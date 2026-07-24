-module(client).
-include("data.hrl").

-behaviour(gen_server).
-export([join/2,chat/1,leave/0]).

%% API
-export([ stop/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(data, {client,
               server}).

stop(Name) ->
    gen_server:call(Name, stop).

init(UserName) ->
    {ok, #data{client = UserName}}.

handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({check, RoomID}, _From, State) ->
    case State#data.server of
        RoomID ->
            {reply, "you are already in this room", State};
        Other ->
            {reply, "your are in room " ++ integer_to_list(Other) ++
            ". Please leave this room first!", State}
    end;

handle_call(is_alive, _From, State) ->
    {reply, yes, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({chat, Message}, State) ->
    gen_server:cast({global, State#data.server}, {chat, Message, State#data.client}),
    {noreply, State};

handle_cast({update, RoomID}, State) ->
    {noreply, State#data{server = RoomID}};

handle_cast({receive_msg, #message{server = Server,
                                   user = UserName,
                                   time = {{Y, M, D}, {H, Min, S}},
                                   msg = Message}}, State) ->
    io:format("[Room ~p] [~p/~p/~p - ~p:~p:~p] [~p said]: ~p~n",
                            [Server, D, M, Y, H, Min, S, UserName, Message]),
    {noreply, State};

handle_cast(leave, State) ->
    gen_server:cast({global, State#data.server}, {leave, State#data.client}),
    {noreply, State};

handle_cast({leave_notify, UserName}, State) ->
    io:format("[~p] just left!~n", [UserName]),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

join(RoomID, UserName) ->
    % io:format("ping to ~p~n", [?SERVER]),
    net_adm:ping(?SERVER),
    timer:sleep(500),
    io:format("Wating for connect..~n"),
    case gen_server:start_link({local, ?MODULE}, ?MODULE, UserName, []) of
        {ok, _} ->
            join2(RoomID, UserName);
        {error, {already_started,_}} ->
            gen_server:call(?MODULE, {check, RoomID});
        Any ->
            Any
    end.
join2(RoomID, UserName) ->
    try gen_server:call({global, RoomID}, {join, UserName, node()}) of
        approved ->
            gen_server:cast(?MODULE, {update, RoomID}),
            "approved";
        Msg ->
            gen_server:stop(?MODULE),
            Msg
    catch
        _:_ ->
            gen_server:stop(?MODULE),
            "room is not exist"
    end.
chat(Message) ->
    gen_server:cast(?MODULE, {chat, Message}).

leave() ->
    io:format("leaving..~n"),
    gen_server:cast(?MODULE, leave),
    timer:sleep(200),
    gen_server:stop(?MODULE).
