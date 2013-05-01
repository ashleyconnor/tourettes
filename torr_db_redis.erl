-module(torr_db_redis).
-author("Tobias O, David H").

% Startup stuff
init() -> ok.

% Are we currently tracking this hash?
hash_exists(Hash) -> ok.

% Add a client to the tracking of a hash. If the hash is not yet tracked, start
% tracking it, with the one client.
add_client(Hash,Client) -> ok.

% Gets a list of some number of clients that all are connected to the torrent
% tracked by Hash.
get_clients(Hash) -> ok.

% Removes a client from the tracking list for Hash
remove_client(Hash,Client) -> ok.
