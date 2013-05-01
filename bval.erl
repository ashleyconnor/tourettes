-module(bval). 
-import(lists,[foldl/3]).
-export([bencode/1]).

-compile(export_all).

bencode(Dict) when element(1,Dict) == dict ->
   BFun = fun(Key,Val,Acc) -> 
         {BKey,BVal} = {bencode(Key),bencode(Val)},
         <<Acc/binary,BKey/binary,BVal/binary>> end,
   BinDict = dict:fold(BFun,<<>>,Dict),
   <<$d,BinDict/binary,$e>>;

bencode(List) when is_list(List) ->
   BList = foldl(
      fun(Elem, Acc) -> 
            BElem = bencode(Elem),
            <<Acc/binary,BElem/binary>>
      end, <<>>, List),
   <<$l,BList/binary,$e>>;

bencode(Str) when is_binary(Str) ->
   S = integer_to_binary(bit_size(Str) div 8),
   <<S/binary,$:,Str/binary>>;

bencode(Int) when is_integer(Int) -> 
   BInt = foldl(fun(E,Acc) -> <<Acc/binary,E>> end, 
                <<>>, integer_to_list(Int)),
   <<$i,BInt/binary,$e>>.

% Converts an integer into a binary
% O(log10 N)
integer_to_binary(N) when N < 10 -> <<(N+48)>>;
integer_to_binary(N) -> 
   Num = N rem 10,
   Rest = integer_to_binary(N div 10),
   <<Rest/binary,(Num+48)>>.
