%%%-------------------------------------------------------------------
%%% File    : torr_main.erl
%%% Authors  : Tobias O & David H
%%% Description : 
%%%
%%% Created : 05 Apr 2009
%%%-------------------------------------------------------------------
-module(torr_main).
-export([init/1]).

init(Port) -> spawn(fun() ->
   process_flag(trap_exit,true),
   torr_server:init(tcp,Port),
   torr_server:init(udp,Port+1),
   torr_tracker:init(),
   super()
end).
   

super() ->
   receive
      {'EXIT',_,normal} -> super();
      {'EXIT',Pid,Reason} ->
         io:format("Process crash ~w:~w",[Pid,Reason]),
         super()
   end.
