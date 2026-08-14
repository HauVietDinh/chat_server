-module(chat_room_tests).
-include_lib("eunit/include/eunit.hrl").

start_room_success_test_() ->
    fun start_room_success_test/0.

start_room_success_test() ->
    with_chat_server_sup(fun() ->
        ?assertMatch({ok, _Pid}, chat_server_sup:create_room(111)),
        ?assertMatch({ok, _Pid}, chat_server_sup:create_room(222)),
        ok
    end).

duplicate_room_id_should_fail_test_() ->
    fun duplicate_room_id_should_fail_test/0.

duplicate_room_id_should_fail_test() ->
    with_chat_server_sup(fun() ->
        ?assertMatch({ok, _Pid}, chat_server_sup:create_room(222)),
        ?assertMatch({error, _Reason}, chat_server_sup:create_room(222)),
        ok
    end).

with_chat_server_sup(Fun) ->
    case whereis(chat_server_sup) of
        undefined ->
            {ok, SupPid} = chat_server_sup:start_link(),
            Started = true;
        _Pid ->
            SupPid = undefined,
            Started = false
    end,
    try
        Fun()
    after
        case Started of
            true -> exit(SupPid, shutdown);
            false -> ok
        end
    end.
