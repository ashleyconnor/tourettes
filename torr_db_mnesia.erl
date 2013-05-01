-module(torr_db_mnesia).
-author("Tobias O").

% -include_lib("/stdlib/include/qlc.hrl").

% Duplicate from torr_tracker. Gotta solve the dependencies some day
-record(client,{ip, port, down, up, left, seeding}).
-record(torrent,{info_hash,clients = dict:new() }).

% TODO: Perhaps in mnesia it would be a better approach to just give each client
% connected to a client a row in the table with the torrent as primary key and
% ip as secondary key? Then retrieval and updating becomes WAY easier than with
% the dictionary approach above.

init() ->
    % Start mnesia
    mnesia:start(),
    % Create database on this node
    mnesia:create_schema([node()]),
    % Create torrent table.
    % Ram copies on all nodes, matching the torrent record
    mnesia:creata_table(torrent,[{ram_copies, nodes()},
                                 {attributes, record_info(fields, torrent)},
                                 {type,set}]),
    ok.

hash_exists(Hash) ->
    F = fun() -> mnesia:read(torrent,Hash) end,
    Val = mnesia:transaction(F),
    length(Val) > 0.

add_client(Hash,Client) -> ok.

get_clients(Hash) -> ok.

remove_client(Hash,Client) -> ok.

% Handy shortcut for single queries using QLC
% Borrowed frow Programming Erlang by Joe Armstrong.
do(Q) -> 
    F = fun() -> qlc:e(Q) end,
    {atomic,Val} = mnesia:transaction(F),
    Val.
