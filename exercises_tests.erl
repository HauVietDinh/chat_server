%% =============================================================================
%% EUnit tests
%% =============================================================================
-module(exercises_tests).
% -compile(export_all).
-include_lib("eunit/include/eunit.hrl").
-include("exercises.hrl").
%%%=============================================================================
%%% Phase 2: Program Structure & Sequential Logic
%%% Get familiar with Modules and Functions, and write your first sequential
%%% programs.
%%%=============================================================================
trim_blank_test_() ->
    [
      ?_assertEqual("", exercises:trim_blank("")),
      ?_assertEqual("", exercises:trim_blank("     ")),
      ?_assertEqual("a", exercises:trim_blank("a")),
      ?_assertEqual("a", exercises:trim_blank("  a")),
      ?_assertEqual("a", exercises:trim_blank("a   ")),
      ?_assertEqual("a b", exercises:trim_blank("   a b   ")),
      ?_assertEqual("Welcome to Erlang !",
                    exercises:trim_blank("     Welcome to Erlang !          ")),
      %% Only trims spaces (ASCII 32), not tabs/newlines:
      ?_assertEqual("\tHi\t", exercises:trim_blank("\tHi\t")),
      ?_assertEqual("\nHi\n", exercises:trim_blank("\nHi\n"))
    ].

remove_duplicate_test_() ->
    [
      ?_assertEqual([], exercises:remove_duplicate([])),
      ?_assertEqual([1], exercises:remove_duplicate([1])),
      ?_assertEqual([1, 2, 3, 4],
                    exercises:remove_duplicate([1, 2, 3, 1, 4, 1, 2])),
      ?_assertEqual([a, b, c],
                    exercises:remove_duplicate([a, b, a, c, b, c])),
      %% Uses =:= equality, so 1 and 1.0 are different:
      ?_assertEqual([1, 1.0], exercises:remove_duplicate([1, 1.0, 1, 1.0])),
      %% Works with mixed terms:
      ?_assertEqual([x, {x, 1}, [x], <<"x">>],
                    exercises:remove_duplicate([x, {x, 1}, x, [x], [x], <<"x">>,
                                                <<"x">>]))
    ].

collatz_test_() ->
    [
      ?_assertEqual([1], exercises:collatz(1)),
      ?_assertEqual([2, 1], exercises:collatz(2)),
      ?_assertEqual([3, 10, 5, 16, 8, 4, 2, 1], exercises:collatz(3)),
      ?_assertEqual([7, 22, 11, 34, 17, 52, 26, 13, 40, 20, 10, 5, 16, 8, 4, 2,
                     1], exercises:collatz(7))
    ].

skeleton_test_() ->
    [
      ?_assertEqual([], exercises:skeleton([])),
      ?_assertEqual([[]], exercises:skeleton([[]])),
      ?_assertEqual([[[]], [], []],
                    exercises:skeleton([1, [2, [3, 4]], 5, 6, [7], []])),
      ?_assertEqual([[], [], [[]], [[], [[]]]],
                    exercises:skeleton([a, [], [1], [x, [y, z]], 9,
                                        [[], [0, [1]]]]))
    ].

eliminate_test_() ->
    [
      ?_assertEqual([], exercises:eliminate(a, [])),
      ?_assertEqual([b, c], exercises:eliminate(a, [a, b, a, c, a])),
      ?_assertEqual([a, [c, d, [a, []]], e],
                    exercises:eliminate(b, [a, b, [b, c, d, [a, [b]]], e])),
      ?_assertEqual([a, b, [b, c, d, [a]], e],
                    exercises:eliminate([b], [a, b, [b, c, d, [a, [b]]], e])),
      %% Remove empty list value:
      ?_assertEqual([a, [b], c],
                    exercises:eliminate([], [a, [], [b], [], c])),
      %% Value is a tuple:
      ?_assertEqual([x, [y, []], z],
                    exercises:eliminate({k, 1}, [x, {k, 1},
                                                 [y, {k, 1}, [{k, 1}]], z]))
    ].

quicksort_test_() ->
    [
      ?_assertEqual([], exercises:quicksort([])),
      ?_assertEqual([1], exercises:quicksort([1])),
      ?_assertEqual([1, 2, 3, 4, 5, 6, 7, 8],
                    exercises:quicksort([5, 3, 7, 8, 4, 1, 6, 2])),
      ?_assertEqual([1, 1, 2, 2, 3, 3],
                    exercises:quicksort([3, 1, 2, 3, 2, 1])),
      ?_assertEqual([-3, -1, 0, 2, 5],
                    exercises:quicksort([0, -1, 5, -3, 2]))
    ].

sqrt_test_() ->
    [
      %% Check closeness rather than exact float:
      ?_assert(abs(exercises:sqrt(12) - 3.4641016151377544) < 0.00001),
      ?_assert(abs(exercises:sqrt(2) - 1.41421356237) < 0.00001),
      ?_assert(abs(exercises:sqrt(1) - 1.0) < 0.00001),
      ?_assert(abs(exercises:sqrt(100) - 10.0) < 0.00001)
    ].

zap_gremlins_test_() ->
    [
      ?_assertEqual([], exercises:zap_gremlins([])),
      ?_assertEqual("ABC", exercises:zap_gremlins("ABC")),
      ?_assertEqual("\n\r ~",
                    exercises:zap_gremlins([10, 13, 31, 32, 126, 127])),
      ?_assertEqual("This is a string in Erlang!",
                    exercises:zap_gremlins(
                      [84, 104, 105, 115, 32, 235, 105, 115, 3, 32, 97, 12, 32,
                       115, 116,  114, 105, 110, 103, 32, 105, 127, 110, 32, 69,
                       114, 108, 11, 14, 97, 110, 103, 33]))
    ].

accumulate_test_() ->
    [
      ?_assertEqual([], exercises:accumulate(fun(X) -> X end, [])),
      ?_assertEqual([1, 4, 9, 16, 25],
                    exercises:accumulate(fun(X) -> X*X end, [1, 2, 3, 4, 5])),
      ?_assertEqual(["a!", "bb!", "ccc!"],
                    exercises:accumulate(fun(S) -> S ++ "!" end,
                                         ["a", "bb", "ccc"]))
    ].

%%%=============================================================================
%%% Phase 3: Concurrency & Data Foundations
%%% Get familiar with concurrent logic and the data/application foundations used
%%% in real Erlang systems.
%%%=============================================================================
user_tab_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [
        fun init_inserts_three_users/0,
        fun add_user_inserts_user/0,
        fun remove_user_deletes_user/0,
        fun remove_all_vip_deletes_only_vips/0,
        fun get_user_info_returns_phone_and_vip/0]
    }.

setup() ->
    ok = exercises:stop_users_table(), % ensure clean start even if rerun
    ok = exercises:init_user_tab().

cleanup(_State) ->
    ok = exercises:stop_users_table().

%%------------------------------------------------------------------------------
%% Tests
%%------------------------------------------------------------------------------
init_inserts_three_users() ->
    %% We already called init_user_tab() in setup/0, so just verify content.
    ?assertEqual(3, ets:info(?USERS_TAB, size)),
    ?assertMatch({"Bob",   {111111, true}},  exercises:get_user_info("Bob")),
    ?assertMatch({"Alice", {222222, false}}, exercises:get_user_info("Alice")),
    ?assertMatch({"Anna",  {333333, true}},  exercises:get_user_info("Anna")),
    ok.

add_user_inserts_user() ->
    %% Add a new non-vip user and verify lookup result via get_user_info/1.
    true = exercises:add_user(#user{name="Eve", age=30, phone=444444, address="US", vip=false}),
    ?assertEqual(4, ets:info(?USERS_TAB, size)),
    ?assertEqual({"Eve", {444444, false}}, exercises:get_user_info("Eve")).

remove_user_deletes_user() ->
    %% Remove existing user and ensure it’s gone from ETS.
    true = exercises:remove_user("Alice"),
    ?assertEqual([], ets:lookup(?USERS_TAB, "Alice")),
    ?assertEqual(3, ets:info(?USERS_TAB, size)). %% Bob/Anna/Eve remain

remove_all_vip_deletes_only_vips() ->
    %% Remove vip users (Bob and Anna). Eve is non-vip, Alice already removed.
    true = exercises:remove_all_vip(),
    ?assertEqual([], ets:lookup(?USERS_TAB, "Bob")),
    ?assertEqual([], ets:lookup(?USERS_TAB, "Anna")),
    ?assertNotEqual([], ets:lookup(?USERS_TAB, "Eve")),
    ?assertEqual(1, ets:info(?USERS_TAB, size)).

get_user_info_returns_phone_and_vip() ->
    %% Ensure still correct for remaining user(s)
    ?assertEqual({"Eve", {444444, false}}, exercises:get_user_info("Eve")).
