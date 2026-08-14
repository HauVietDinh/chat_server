-module(chat_server_sup).
-behaviour(supervisor).

-export([start_link/0, create_room/1, init/1]).

start_link() ->
    case supervisor:start_link({local, ?MODULE}, ?MODULE, []) of
        {ok, Pid} = Result ->
            unlink(Pid),
            Result;
        Error ->
            Error
    end.

create_room(RoomId) ->
    ChildSpec = #{id => {chat_room, RoomId},
                  start => {chat_room, start_link, [RoomId]},
                  restart => transient,
                  shutdown => 5000,
                  type => worker,
                  modules => [chat_room]},
    supervisor:start_child(?MODULE, ChildSpec).

init([]) ->
    SupFlags = #{strategy => one_for_one,
                 intensity => 1,
                 period => 5},
    {ok, {SupFlags, []}}.
