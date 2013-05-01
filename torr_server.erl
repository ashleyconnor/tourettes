-module(torr_server).
-author("Tobias Olausson").

-import(gen_tcp,[listen/2,accept/1]).
-import(gen_udp,[open/2,send/4]).
-import(torr_client,[handle_tcp/1,handle_udp/3]).

-export([init/2]).

init(tcp,Port) ->
   {ok,Listen} = listen(Port,[binary]),
   Pid = spawn_link(fun() ->
            io:format("Starting TCP server\n"),
            tcp_loop(Listen)
         end),
   register(tcp_server,Pid),
   Pid;

init(udp,Port) ->
   {ok,Socket} = open(Port,[binary]),
   Pid = spawn_link(fun() ->
            process_flag(trap_exit,true),
            io:format("Starting UDP server\n"),
            udp_loop(Socket)
         end),
   gen_udp:controlling_process(Socket,Pid),
   register(udp_server,Pid),
   Pid.


udp_loop(Socket) ->
   receive
      {udp,Socket,Host,Port,Data} ->
         spawn_link(fun() -> handle_udp(Host,Port,Data) end),
         udp_loop(Socket);
      {reply,Address,Port,Data} -> 
         send(Socket,Address,Port,Data),
         udp_loop(Socket);
      {'EXIT',_Pid,normal} -> udp_loop(Socket);
      {'EXIT',_Pid,Reason} -> 
         io:format("UDP Client terminated with reason:~w\n",[Reason]),
         udp_loop(Socket)
   end.

tcp_loop(Listen) ->
   case accept(Listen) of
      {ok,Socket} -> 
         {ok,{IP,_}} = inet:peername(Socket),
         io:format("~w connected\n",[IP]),
         Pid = spawn_link(fun() -> 
                  process_flag(trap_exit,true),
                  handle_tcp(Socket)
               end),
         gen_tcp:controlling_process(Socket,Pid),
         tcp_loop(Listen);
      {error,Reason} -> exit(Reason)
   end.
