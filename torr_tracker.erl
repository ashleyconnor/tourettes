-module(torr_tracker).
-author("Tobias O, David H").

% TODO: Convert the tracker code to use a more general approach for distributed
% database system, and let the underlying DBMS take care of the data handling.
% TODO: OTP-ize it.

-import(dict,[fetch/2,find/2]).
-export([init/0]).

% Clients are represented with ip, port and some torrent statistics (for a
% specific torrent, that is! Clients should only be found inside the torrent
% record. In each torrent, the client field should be a hash table where ip is
% the key. For a stripped down version, one could remove all data except ip and
% port from the client record
-record(client,{ip, port, down, up, left, seeding}).
-record(torrent,{info_hash,clients = dict:new() }).

init() ->
   Pid = spawn_link(fun() -> 
            TableID = ets:new(torr_db,[bag,protected]),
            tracker(TableID) 
         end),
   register(torr_tracker,Pid),
   Pid.

tracker(TableID) -> 
   receive 
      {{request,announce},Data,Pid} ->
           Hash  = fetch(<<"info_hash">>,Data), 
%               io:format("Announcing for hash: ~w\n",[Hash]),
           IP    = fetch(<<"ip">>,Data),
           Port  = fetch(<<"port">>,Data), 
           Elem  = <<IP/binary,Port:16>>,
           Up    = fetch(<<"uploaded">>,Data),
           Down  = fetch(<<"downloaded">>,Data),
           Left  = fetch(<<"left">>,Data),

           case ets:lookup(TableID,Hash) of
              []       -> 
                 Pid ! {{response,error},<<"not found">>},
                 Value = {Elem,Up,Down,Left},
                 ets:insert(TableID,{Hash,Value});
              TorrData ->
%                     io:format("Found Hash\n"),
                 Peers = [ Peer || {_Hash,Peer} <- TorrData],
                 Pid ! {{response,peers},Peers},
                 case find(<<"event">>,Data) of
                    {ok,3} ->
                       % This is such an ugly hack
%                           io:format("Deleting client\n"),
                       Deleted = lists:keydelete(Elem,1,Peers),
                       case Deleted of
                          [] -> ets:delete(TableID,Hash);
                          _  -> lists:foreach(fun(E) -> ets:insert(TableID,{Hash,E}) end,Deleted)
                       end;
                    _Other ->
%                           io:format("Action: ~w\n",[Other]),
%                           io:format("Updating client\n"),
                       Value = {Elem,Up,Down,Left},
                       ets:insert(TableID,{Hash,Value})
                 end
           end,
           tracker(TableID);
        {{request,scrape},_,Pid} ->
           Pid ! {{response,scrape_error},<<"Not supported">>},
           tracker(TableID)
   end.

