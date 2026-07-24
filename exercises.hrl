
-record(user, {
    name = "" :: string(),
    age :: undefined | integer(),
    phone :: undefined | integer(),
    address = "" :: string(),
    vip = false :: boolean()
}).

-define(USERS_TAB, users_tab).
