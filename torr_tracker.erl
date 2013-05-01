-module(torr_tracker).
-author("Tobias Olausson").

-import(dict,[fetch/2,find/2]).
-export([init/0]).

-record(torrent,{
      info_hash, ip, port,
      down, up, left, seeding}).

init() ->
   Pid = spawn_link(fun() -> 
            TableID = ets:new(torr_db,[bag,protected]),
            tracker(TableID) 
         end),
   register(torr_tracker,Pid),
   Pid.

tracker(TableID) -> 
   receive 
      {{request,Action},Data,Pid} ->
         case Action of
            announce -> 
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
                        Other ->
%                           io:format("Action: ~w\n",[Other]),
%                           io:format("Updating client\n"),
                           Value = {Elem,Up,Down,Left},
                           ets:insert(TableID,{Hash,Value})
                     end
               end,
               tracker(TableID);

            scrape -> 
               Pid ! {{response,scrape_error},<<"Not supported">>},
               tracker(TableID)
         end
   end.

