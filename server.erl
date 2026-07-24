-module(server).
-include("data.hrl").

-export([create_room/0, create_room/1]).
-behaviour(gen_server).

%% API
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {server = [],
                users = [],
                msg_id = 1}).

init(ID) ->
    monitor_clients(),
    {ok, #state{server = ID}}.

send_msg(Node, Server) ->
    [send_to_client(Msg, Node) || Msg <- ets:match_object(message,
                                            {'_', '_', Server, '_', '_', '_'})],
    ok.


handle_call({join, UserName, Node}, _From, #state{users = Users} = State)->
    case is_exist_name(UserName, Users) of
        true ->
            {reply, atom_to_list(UserName) ++ " is exist, please select other names", State};
        _ ->
            io:format("~p just joined room ~p!~n", [UserName, State#state.server]),
            send_msg(Node, State#state.server),
            {reply, approved, State#state{users = Users ++ [{UserName, Node}]}}
    end;

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({chat, Message, UserName}, #state{msg_id = MsgId,
                                              users = Users,
                                              server = Server} = State) ->
    {{Y, M, D}, {H, Min, S}} = erlang:localtime(),
    io:format("[Room ~p] [~p/~p/~p - ~p:~p:~p] [~p said]: ~p~n",
                                [Server, D, M, Y, H, Min, S, UserName, Message]),
    Msg = #message{id = MsgId,
                   server = Server,
                   user = UserName,
                   time = {{Y, M, D}, {H, Min, S}},
                   msg = Message},
    [send_to_client(Msg, Node) || {User, Node} <- Users, User =/= UserName],
    ets:insert(message, Msg),

    {noreply, State#state{msg_id = MsgId + 1}};

handle_cast({leave, UserName}, #state{users = Users} = State) ->
    io:format("~p just left!~n", [UserName]),
    [notify_to_client(UserName, Node)|| {User, Node} <- Users, User =/= UserName],
    {noreply, State#state{users = lists:keydelete(UserName, 1, Users)}};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(is_alive, #state{ users = Users} = State) ->
    [is_alive(User, Node) || {User, Node} <- Users],
    monitor_clients(),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

create_room() ->
    {_, _, ID} = erlang:timestamp(),
    create_room(ID).
create_room(ID) ->
    % {ok, File} = file:open("./data.hrl", [append]),
    % Node = node(),
    % ok = file:write(File, "\n-define(SERVER, '" ++ atom_to_list(Node) ++ "').\n"),
    % ok = file:close(File),
    case global:whereis_name(ID) of
        undefined ->
            gen_server:start_link({global, ID}, ?MODULE, ID, []);
        _ ->
            io:format("Room ~p is exist~n",[ID])
    end,
    case ets:info(message) of
        undefined ->
            ets:new(message, [ordered_set, public, named_table, {keypos, 2}]);
        _ ->
            ok
    end,
    io:format("Room ID: ~p~n", [ID]).

% close_room(RoomID) ->
%     gen_server:call({global, RoomID}, {stop}).

send_to_client(Msg, Node) ->
    gen_server:cast({client, Node}, {receive_msg, Msg}).

notify_to_client(UserName, Node) ->
    gen_server:cast({client, Node}, {leave_notify, UserName}).

monitor_clients() ->
    erlang:send_after(1000, self(), is_alive).

is_exist_name(UserName, ListClient) ->
    case [User || {User, _} <- ListClient, User == UserName] of
        [] -> false;
        _ -> true
    end.

is_alive(UserName, Node) ->
    try
        gen_server:call({client, Node}, is_alive)
    catch
        _:_ ->
            gen_server:cast(self(), {leave, UserName})
    end.