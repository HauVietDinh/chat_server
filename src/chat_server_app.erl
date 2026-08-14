-module(chat_server_app).
-behaviour(application).

-export([start/2, stop/1, create_room/1]).

start(_Type, _Args) ->
    chat_server_sup:start_link().

create_room(RoomId) when is_integer(RoomId) ->
    {ok, Pid} = chat_server_sup:create_room(RoomId),
    io:format("Created room with id: ~p~n", [RoomId]),
    {ok, Pid};
create_room(RoomId) ->
    {error, "room id must be an integer, got: " ++
            io_lib:format("~p", [RoomId])}.

stop(_State) ->
    ok.
