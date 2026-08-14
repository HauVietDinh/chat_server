-module(chat_user_tests).
-include_lib("eunit/include/eunit.hrl").

user_join_chat_exit_success_test_() ->
    fun user_join_chat_exit_success_test/0.

user_join_chat_exit_success_test() ->
    with_server_room(fun(RoomId) ->
        {ok, UserPid} = gen_server:start_link({local, user_a}, chat_user, "alice", []),
        ?assertEqual(ok, gen_server:call(UserPid, {join, RoomId})),
        ?assertEqual(ok, gen_server:call(UserPid, {chat, "hello room"})),
        ?assertEqual(ok, gen_server:call(UserPid, leave)),
        gen_server:stop(UserPid),
        ok
    end).

multi_user_notifications_and_history_test_() ->
    fun multi_user_notifications_and_history_test/0.

multi_user_notifications_and_history_test() ->
    with_server_room(fun(RoomId) ->
        {ok, User1} = gen_server:start_link({local, user_b}, chat_user, "alice", []),
        {ok, User2} = gen_server:start_link({local, user_c}, chat_user, "bob", []),

        ?assertEqual(ok, gen_server:call(User1, {join, RoomId})),
        ?assertEqual(ok, gen_server:call(User1, {chat, "hello from alice"})),

        ?assertEqual(ok, gen_server:call(User2, {join, RoomId})),

        ?assertMatch({messages, _}, process_info(User1, messages)),
        ?assertMatch({messages, _}, process_info(User2, messages)),

        ?assertEqual(ok, gen_server:call(User2, {chat, "hello from bob"})),

        ?assertMatch({messages, _}, process_info(User1, messages)),
        ?assertMatch({messages, _}, process_info(User2, messages)),

        gen_server:stop(User1),
        gen_server:stop(User2),
        ok
    end).

join_nonexistent_room_test_() ->
    fun join_nonexistent_room_test/0.

join_nonexistent_room_test() ->
    with_server_room(fun(_RoomId) ->
        {ok, UserPid} = gen_server:start_link({local, user_d}, chat_user, "ghost", []),
        ?assertMatch({error, room_not_found}, gen_server:call(UserPid, {join, 999999})),
        gen_server:stop(UserPid),
        ok
    end).

join_second_room_at_same_time_should_fail_test_() ->
    fun join_second_room_at_same_time_should_fail_test/0.

join_second_room_at_same_time_should_fail_test() ->
    with_server_room(fun(_RoomId) ->
        Room1 = 1001,
        Room2 = 1002,
        ?assertMatch({ok, _}, chat_server_sup:create_room(Room1)),
        ?assertMatch({ok, _}, chat_server_sup:create_room(Room2)),

        {ok, UserPid} = gen_server:start_link({local, user_e}, chat_user, "double_join", []),
        ?assertEqual(ok, gen_server:call(UserPid, {join, Room1})),
        ?assertMatch({error, already_in_room, Room1}, gen_server:call(UserPid, {join, Room2})),
        gen_server:stop(UserPid),
        ok
    end).

with_server_room(Fun) ->
    File = "server.node",
    ok = file:write_file(File, atom_to_list(node())),
    case whereis(chat_server_sup) of
        undefined ->
            {ok, SupPid} = chat_server_sup:start_link(),
            Started = true;
        _Pid ->
            SupPid = undefined,
            Started = false
    end,
    try
        RoomId = 777,
        ?assertMatch({ok, _}, chat_server_sup:create_room(RoomId)),
        Fun(RoomId)
    after
        case Started of
            true -> exit(SupPid, shutdown);
            false -> ok
        end,
        file:delete(File)
    end.
