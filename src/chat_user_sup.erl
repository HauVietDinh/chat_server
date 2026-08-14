-module(chat_user_sup).
-behaviour(supervisor).

-export([start_link/1, init/1]).

start_link(UserName) ->
    case supervisor:start_link({local, ?MODULE}, ?MODULE, [UserName]) of
        {ok, Pid} = Result ->
            unlink(Pid),
            Result;
        Error ->
            Error
    end.

init([UserName]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 3,
        period => 5
    },

    ChildSpec = #{
        id => chat_user,
        start => {chat_user, start_link, [UserName]},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [chat_user]
    },

    {ok, {SupFlags, [ChildSpec]}}.
