-module(torr_db_mnesia).
-author("Tobias O").
-compile(export_all).

% Needed for QLC to work
-include_lib("stdlib/include/qlc.hrl").

% Really a minimalistic approach to tracking
-record(torrent,{info_hash,ip}).

% TODO: Persistency and loading of tables?

init() ->
    mnesia:start(),
    mnesia:create_schema([node()]),
    mnesia:create_table(torrent,[{attributes, record_info(fields, torrent)},
                                 {type,bag}]),
    % Do we really need this?
    mnesia:add_table_index(torrent,ip),
    ok.

hash_exists(Hash) ->
    Rows = get_clients(Hash),
    length(Rows) > 0.

% Client is assumed to be a hashmap of attributes
add_client(Hash,Client) ->
    IP = dict:fetch(<<"ip">>,Client),
    Record = #torrent{info_hash = Hash, ip = IP},
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

get_clients(Hash) -> 
    Q = qlc:q([T#torrent.ip || T <- mnesia:table(torrent), 
                               T#torrent.info_hash =:= Hash]),
    F = fun() -> qlc:e(Q) end,
    {atomic,Clients} = mnesia:transaction(F),
    Clients.

get_torrents(Client) -> 
    IP = dict:fetch(<<"ip">>,Client),
    Q = qlc:q([C#torrent.info_hash || C <- mnesia:table(torrent),
                                      C#torrent.ip =:= IP]),
    F = fun() -> qlc:e(Q) end,
    {atomic,Hashes} = mnesia:transaction(F),
    Hashes.

remove_client(Hash,Client) ->
    IP = dict:fetch(<<"ip">>,Client),
    Record = #torrent{info_hash = Hash, ip = IP},
    F = fun() -> mnesia:delete_object(Record) end,
    mnesia:transaction(F).


