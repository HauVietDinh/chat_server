%%%===================================================================
%%% Erlang Code Exercise (5 Phases)
%%%===================================================================
-module(exercises).

%% Phase 1
-export([]).

%% Phase 2
-export([trim_blank/1,
         remove_duplicate/1,
         collatz/1,
         skeleton/1,
         eliminate/2,
         quicksort/1,
         sqrt/1,
         zap_gremlins/1,
         accumulate/2]).

%% Phase 3
-export([init_user_tab/0,
         stop_users_table/0,
         add_user/1,
         remove_user/1,
         remove_all_vip/0,
         get_user_info/1,
         start_ring/2]).

%% Phase 4
-export([]).

%% Phase 5
-export([]).

-include("exercises.hrl").

%%%=============================================================================
%%% Phase 1: Foundation Knowledge
%%% Get familiar with syntax, data types, and use the Erlang shell for practice.
%%% Start erlang shell: erl
%%%=============================================================================

%%------------------------------------------------------------------------------
%% 1. Assign appropriate values to the variable Term so that each of the
%%    following functions returns true:
%%    is_integer(Term), is_float(Term), is_atom(Term), is_list(Term),
%%    is_binary(Term), is_tuple(Term), is_number(Term), is_boolean(Term).
%%------------------------------------------------------------------------------
    % 1> Term = 10,
    %    is_integer(Term).
    % true.

    % 2> Term = 3.14,
    %    is_float(Term).
    % true.

    % 3> Term = hello,
    %    is_atom(Term).
    % true.

    % 4> Term = [1,2,3],
    %    is_list(Term).
    % true.

    % 5> Term = <<"abc">>,
    %    is_binary(Term).
    % true.

    % 6> Term = {ok, 1},
    %    is_tuple(Term).
    % true.

    % 7> Term = 42,
    %    is_number(Term).
    % true.

    % 8> Term = true,
    %    is_boolean(Term).
    % true.
%%------------------------------------------------------------------------------
%% 2. Using pattern matching to extract the value of 'company' from this list:
%% L = [{company, "Endava"}, {office, "Vietnam"}, {discipline, "Development"}].
%%------------------------------------------------------------------------------
    % 1> L = [{company, "Endava"}, {office, "Vietnam"},
    %         {discipline, "Development"}].
    % 2> [{company, Company} | _] = L,
    %    Company.
    % "Endava"

%%------------------------------------------------------------------------------
%% 3. Using list comprehension to take all positive even numbers in a list
%%    Example: [3, -2, 5, -10, -1, 6, 8] -> [6, 8].
%%------------------------------------------------------------------------------
    % 1> L = [3, -2, 5, -10, -1, 6, 8].
    % 2> [X || X <- L, X > 0, X rem 2 =:= 0].
    % [6,8]

%%------------------------------------------------------------------------------
%% 4. Using list comprehension to double the values of this list and remove
%%    if element is zero.
%%    Example: [1, 2, 0, 3, 0, 4] -> [2, 4, 6, 8].
%%------------------------------------------------------------------------------
    % 1> L = [1, 2, 0, 3, 0, 4].
    % 2> [X * 2 || X <- L, X =/= 0].
    % [2,4,6,8]

%%%=============================================================================
%%% Phase 2: Program Structure & Sequential Logic
%%% Get familiar with Modules and Functions, and write your first sequential
%%% programs.
%%%=============================================================================

%%------------------------------------------------------------------------------
%% 01. trim_blank(Text) -> NewText
%%     Write a function to trim blank spaces at head/tail of a string
%%     Do not use string:trim(String)!
%%     Example: "     Welcome to Erlang !          " -> "Welcome to Erlang !".
%%------------------------------------------------------------------------------
trim_blank(Text) when is_list(Text) ->
    trim_right(trim_left(Text)).

trim_left([32 | T]) -> trim_left(T);
trim_left(T) -> T.

reverse(Text) ->
    reverse(Text, []).

reverse([H | T], Acc) ->
    reverse(T, [H | Acc]);
reverse([], Acc) ->
    Acc.

trim_right(Text) ->
    reverse(trim_left(reverse(Text))).

%%------------------------------------------------------------------------------
%% 02. remove_duplicate(List) -> List
%%     Removes duplicate elements of List, the order of elements must be kept.
%%     Hint: Using List Comprehension
%%     Example: remove_duplicate([1, 2, 3, 1, 4, 1, 2]) -> [1, 2, 3, 4].
%%------------------------------------------------------------------------------
remove_duplicate([H | T]) ->
    WithOutH = [X || X <- T, X =/= H],
    [H | remove_duplicate(WithOutH)];
remove_duplicate([]) ->
    [].

%%------------------------------------------------------------------------------
%% 03. collatz(Integer) -> List
%%     Defined for positive integers n. Returns a list starting with N. Each
%%     subsequent value is computed from the previous value according to:
%%     * The list ends with 1.
%%     * Every even number is followed by N / 2
%%     * Every odd number (except 1) is followed by (3 * N) + 1
%%     Example: collatz(7) -> [7, 22, 11, 34, 17, 52, 26, 13, 40, 20, 10, 5, 16,
%%                             8, 4, 2, 1].
%%------------------------------------------------------------------------------
collatz(1) ->
    [1];
collatz(N) when is_integer(N), N > 0 ->
    if N rem 2 =:= 0 ->
           [N | collatz(N div 2)];
       true ->
           [N | collatz(N*3 + 1)]
    end.

%%------------------------------------------------------------------------------
%% 04. skeleton(List) -> List
%%     Removes all the non-list elements of list List, but retains all the list
%%     structure (the brackets).
%%     Example: skeleton([1, [2, [3, 4]], 5, 6, [7], []]) -> [[[]], [], []].
%%------------------------------------------------------------------------------
skeleton(L) when is_list(L) ->
    [skeleton(E) || E <- L, is_list(E)].

%%------------------------------------------------------------------------------
%% 05. eliminate(Value, List) -> List
%%     Returns the list List with all occurrences of the Value removed, at all
%%     levels, retaining the list (bracket) structure.
%%     Example: eliminate(b, [a, b, [b, c, d, [a, [b]]], e]) ->
%%                     [a, [c, d, [a, []]], e].
%%             eliminate([b], [a, b, [b, c, d, [a, [b]]], e]) ->
%%                     [a, b, [b, c, d, [a]], e].
%%     NOTE: the Value can be anything.
%%------------------------------------------------------------------------------
eliminate(Value, [Value | T]) ->
    eliminate(Value, T);
eliminate(Value, [List | T]) when is_list(List) ->
    [eliminate(Value, List) | eliminate(Value, T)];
eliminate(Value, [H | T]) ->
    [H| eliminate(Value, T)];
eliminate(_Value, []) ->
    [].

%%------------------------------------------------------------------------------
%% 06. quicksort(List) -> List
%%     Return a quicksorted version of the given list.
%%     Example: quicksort([5, 3, 7, 8, 4, 1, 6, 2]) -> [1, 2, 3, 4, 5, 6, 7, 8].
%%------------------------------------------------------------------------------
quicksort([Pivot | Rest]) ->
    Smaller = [X || X <- Rest, X =< Pivot],
    Greater = [X || X <- Rest, X > Pivot],
    quicksort(Smaller) ++ [Pivot] ++ quicksort(Greater);
quicksort([]) ->
    [].

%%------------------------------------------------------------------------------
%% 07. sqrt(Integer) -> Float
%%     Compute the square root of the positive number S, using Newton's method.
%%     That is, choose some arbitrary number, say 2, as the initial
%%     approximation R to the square root; then to get the next approximation,
%%     compute the average of R and N/R. Continue until you have five
%%     significant digits to the right of the decimal point. Do this by taking
%%     an infinite series of approximations, and taking approximations until
%%     they differ by less than 0.00001.
%%     Xo = 2 and Xn+1 = 1/2 (Xn + S/Xn).
%%     Example: sqrt(12) -> 3.4641016151377544.
%%------------------------------------------------------------------------------
sqrt(S) when is_integer(S), S > 0 ->
    sqrt_newton(S, 2).

sqrt_newton(S, Xn) ->
    Xn1 = 0.5 * (Xn + S / Xn),
    case absf(Xn1 - Xn) < 0.00001 of
        true  -> Xn1;
        false -> sqrt_newton(S, Xn1)
    end.

absf(X) when X < 0 -> -X;
absf(X) -> X.

%%------------------------------------------------------------------------------
%% 08. zap_gremlins(Text) -> Text
%%     Remove from the given text all invalid ASCII characters.
%%     The Valid characters are decimal 10 (linefeed), 13 (carriage return) and
%%     32 through 126, inclusive. Remember that Erlang has no "character" type;
%%     a "string" is just a list of ASCII values.
%%     Example: zap_gremlins([84,104,105,115,32,235,105,115,3,32,97,12,32,115,
%%                            116,114,105,110,103,32,105,127,110,32,69,114,108,
%%                            11,14,97,110,103,33]) -> ?
%%------------------------------------------------------------------------------
zap_gremlins(Text) when is_list(Text) ->
    [C || C <- Text, is_valid_ascii(C)].

is_valid_ascii(10) -> true;
is_valid_ascii(13) -> true;
is_valid_ascii(C) when is_integer(C), C >= 32, C =< 126 -> true;
is_valid_ascii(_) -> false.

%%------------------------------------------------------------------------------
%% 09. Implement the accumulate operation, which, given a collection and
%%     an operation to perform on each element of the collection, returns a new
%%     collection containing the result of applying that operation to each
%%     element of the input collection.
%%     Example: Given the collection of numbers: [1, 2, 3, 4, 5]
%%             And the operation: square a number (x => x * x)
%%             Your code should be able to produce the collection of squares:
%%             [1, 4, 9, 16, 25]
%%------------------------------------------------------------------------------
accumulate(Fun, Collection) when is_function(Fun, 1), is_list(Collection) ->
    [Fun(X) || X <- Collection].


%%%=============================================================================
%%% Phase 3: Concurrency & Data Foundations
%%% Get familiar with concurrent logic and the data/application foundations used
%%% in real Erlang systems.
%%%=============================================================================
%%------------------------------------------------------------------------------
%% 01. Define a record user's data include name, age, phone number, address,
%%     vip user (true/false). Then create ets table to store user's data with
%%     this record structure. Add three users:
%%     name   |   age   |   phone number   |   address   |   is vip user?
%%     Bob        18           111111            "VN"          true
%%     Alice      20           222222            "SW"          false
%%     Anna       16           333333            "AU"          true
%%     Write all below functions:
%%     1. Function to add a new user to table.
%%     2. Function to remove a user from table by user name.
%%     3. Function to remove all vip users.
%%     4. Function that given a name then returns the information about phone
%%         number and vip of this user.
%%         Example: get_user_info("Bob") -> {"Bob", {111111, true}}.
%%------------------------------------------------------------------------------
init_user_tab() ->
    ets:new(?USERS_TAB, [named_table, set, public, {keypos, #user.name}]),
    add_user(#user{name = "Bob", age = 18, phone = 111111, address = "VN",
                   vip = true}),
    add_user(#user{name = "Alice", age = 20, phone = 222222, address = "SW",
                   vip = false}),
    add_user(#user{name = "Anna", age = 16, phone = 333333, address = "AU",
                   vip = true}),
    ok.

stop_users_table() ->
    case ets:info(?USERS_TAB) of
        undefined -> ok;
        _ ->
            ets:delete(?USERS_TAB),
            ok
    end.
%% Add a new user
add_user(User = #user{}) ->
    true = ets:insert(?USERS_TAB, User).

%% Remove a user by user name
remove_user(Name) ->
    true = ets:delete(?USERS_TAB, Name).

%% Remove all vip users
remove_all_vip() ->
    %% Get all vip users, then delete by key (name).
    true = ets:match_delete(?USERS_TAB, #user{vip=true, _='_'}).

%% Get phone number and vip information of user by name.
get_user_info(Name) ->
    [#user{phone=Phone,
          vip=Vip}] = ets:lookup(?USERS_TAB, Name),
    {Name, {Phone, Vip}}.

%%------------------------------------------------------------------------------
%% 02. start_ring(N, M) -> ok.
%%     Write a function which starts N processes in a ring,
%%     and sends a message M times around all the processes in the ring.
%%     After the messages have been sent the processes should terminate
%%     gracefully. Messages sent in a ring of processes.
%%     Note: print out "process <Sender> sends message <Numbering> to process
%%     <Receiver>". See the following example.
%%     Example: start_ring(2, 2).
%%         -> create process 1: <0.210.0>
%%         -> create process 2: <0.211.0>
%%             [<0.210.0>,<0.211.0>]
%%             : process 1 sends message 2 to process 2
%%             : process 2 sends message 2 to process 1
%%             : process 1 sends message 1 to process 2
%%             : process 2 sends message 1 to process 1
%%             * process 1 terminated!
%%             * process 2 terminated!
%%------------------------------------------------------------------------------
start_ring(N, M) ->
    %% Spawn  N processes in a ring
    Processes = spawn_ring(N),
    {_, First} = hd(Processes),
    %% Trigger sending around M messages
    First ! {send, M, self()},
    receive
        send_done -> ok
    end,
    %% Terminate all processes
    lists:foreach(fun({_, Pid}) -> Pid ! stop end, Processes).

loop(Id, Right) ->
    receive
        {set_right, R} ->
            loop(Id, R);
        {send, M, Starter} ->
            {RId, RPid} = Right,
            case Id of
                1 when M == 0 ->
                    Starter ! send_done,
                    loop(Id, Right);
                1 ->
                    io:format(": process ~p sends message ~p to process ~p~n",
                              [Id, M, RId]),
                    RPid ! {send, M - 1, Starter},
                    loop(Id, Right);
                _ ->
                    io:format(": process ~p sends message ~p to process ~p~n",
                              [Id, M + 1, RId]),
                    RPid ! {send, M, Starter},
                    loop(Id, Right)
            end;
        stop ->
            io:format(": process ~p terminated!~n", [Id])
    after 1000 ->
        exit("timeout")
    end.

spawn_ring(N) ->
    Processes = [{Id, spawn(fun() ->
                    io:format("-> create process ~p: ~p~n", [Id, self()]),
                    loop(Id, undefined)
                  end)} || Id <- lists:seq(1, N)],
    set_right(Processes, hd(Processes)),
    Processes.

set_right([{_, Pid}, Right | Rest], First) ->
    Pid ! {set_right, Right},
    set_right([Right | Rest], First);
set_right([{_, LastPid}], First) ->
    LastPid ! {set_right, First}.

%%%=============================================================================
%%% Phase 4: OTP & Application Architecture
%%% Learn about OTP and custom application architecture.
%%%=============================================================================
%% 01. Create a chat room (gen_server) and user (gen_server).
%%     The chat room's server and each user will be run on their own terminal
%%     (Linux)/console (Windows). (Read more about Erlang distributed)
%%     When creating chat room, the RoomId will defined. The user will need to know
%%     the RoomId to join into the chat room (e.g. user:join(RoomId, UserName). ).
%%     User can only join once room at the time, they will need to exit the current
%%     room before join another. When the user joins, make sure the UserName is
%%     unique. After the user have joined the chat room, they can send message.
%%     (e.g. user:chat("Hello"). ) When received the message, the server will
%%     format it as record (the data should be included: UserName, Time and Message)
%%     and being store in ETS table for retrieve later on. After stored the message,
%%     the server will send it into to each participant. When received the chat
%%     message, user will display it in the monitor. When a new user joined the
%%     room, the server will send all the chat messages for that user. User can exit
%%     the chat room after joined. When a user exits the chat room, server will
%%     notify other users. To know the users in the room still online, the server
%%     will be spawning a process (I will called it: alive process) for each user
%%     when they successful joined. Alive process will send checking message to the
%%     user if it not gets any response, it will notify the server to remove the user.

%% The model:
%% Alive 1     Alive 2   Alive n   (child of chat room)
%%         \         |         /
%%             [ Chat room ]   (gen_server)
%%         /         |         \
%% User 3       User 2   User n    (gen_server)

%% Note: since the handle_call and handle_cast in gen_server will work differently,
%% so determine which function should be use as call or cast.

%%%=============================================================================
%%% Phase 5: Delivery
%%% Learn tools that support delivering an Erlang-based project.
%%%=============================================================================

