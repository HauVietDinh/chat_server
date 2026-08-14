-record(msg, {room_id, username, time_ms, text}).

%% File where the server startup script writes the server node name
-define(SERVER_NODE_FILE, "server.node").
