-module(torr_parser).
-author("Tobias Olausson").

-import(dict,[is_key/2,store/3]).
-export([parse/2]).

% Main function, should be forked off while
% supplying the caller's Pid as an argument
parse(<<"GET /announce?",Request/binary>>,Pid) -> 
   Req = bin_takewhile($ ,bin_takewhile($\r ,Request)),
   ReqDict = parse_key(Req,<<>>),
   valid(ReqDict),
   Pid ! {{parse_ok,announce},ReqDict};
parse(<<"GET /scrape?",Request/binary>>,Pid) -> 
   Req = bin_takewhile($ ,Request),
   Pid ! {{parse_ok,scrape},scrape(Req)};
parse(_,_) -> exit(bad_request).

% parse_key and parse_val are used when
% parsing a request for announce
parse_key(<<>>,_Key) -> exit(premature_end);
parse_key(<<$&,_Rest/binary>>,_Key) -> exit(premature_amp);
parse_key(<<$=,_Rest/binary>>,<<>>) -> exit(premature_eq);
parse_key(<<$=,Rest/binary>>,Key) -> parse_val(Rest,Key,<<>>);
parse_key(<<Char:8,Rest/binary>>,Key) -> parse_key(Rest,<<Key/binary,Char>>).

parse_val(<<>>,_Key,<<>>) -> exit(premature_end);
parse_val(<<>>,Key,Val) -> store(Key,convert(Key,Val),dict:new());
parse_val(<<$=,_Rest/binary>>,_Key,_Val) -> exit(premature_eq);
parse_val(<<$&,_Rest/binary>>,_Key,<<>>) -> exit(premature_amp);
parse_val(<<$&,Rest/binary>>,Key,Val) ->
   store(Key,convert(Key,Val),parse_key(Rest,<<>>));
parse_val(<<Char:8,Rest/binary>>,Key,Val) -> 
   parse_val(Rest,Key,<<Val/binary,Char>>).

% Parse scrape requests
scrape(<<"info_hash=",Hash/binary>>) -> scrape2(Hash,<<>>).
scrape2(<<>>,<<>>) -> exit(premature_end);
scrape2(<<>>,Acc) -> [ url_decode(Acc,<<>>) ];
scrape2(<<$&,Rest/binary>>,Acc) -> [url_decode(Acc,<<>>) | scrape(Rest) ];
scrape2(<<$=,_Rest/binary>>,_) -> exit(premature_eq);
scrape2(<<Char:8,Rest/binary>>,Acc) -> scrape2(Rest,<<Acc/binary,Char>>).

% Fails if % is followed by non-hex chars,
% or if the string ends in %
url_decode(<<>>,Acc) -> Acc;
url_decode(<<$%>>,_Acc) -> exit(badarg);
url_decode(<<$%,H:8,L:8,Rest/binary>>,Acc) ->
   Value = erlang:list_to_integer([H,L],16),
   url_decode(Rest,<<Acc/binary,Value>>);
url_decode(<<Byte:8,Rest/binary>>,Acc) -> url_decode(Rest,<<Acc/binary,Byte>>).

% Checking for required fields
% TODO make sure compact != 0
valid(Dict) -> case
   is_key(<<"info_hash">>,Dict) and
   is_key(<<"peer_id">>,Dict) and
   is_key(<<"uploaded">>,Dict) and
   is_key(<<"downloaded">>,Dict) and
   is_key(<<"left">>,Dict) and
   is_key(<<"port">>,Dict) of
      false -> exit(missingkeys);
      true -> 
         case dict:find(<<"compact">>,Dict) of
            % This is safe as convert/2 has been called before
            {ok,0} -> exit(notsupported);
            _      -> Dict
         end
   end.

% Converts some fields into integers while leaving other
convert(Key,Val) -> 
   case Key of
      <<"port">>        -> binary_to_integer(Val,0);
      <<"compact">>     -> binary_to_integer(Val,0);
      <<"downloaded">>  -> binary_to_integer(Val,0);
      <<"uploaded">>    -> binary_to_integer(Val,0);
      <<"left">>        -> binary_to_integer(Val,0);
      <<"numwant">>     -> binary_to_integer(Val,0);
      _ -> url_decode(Val,<<>>)
   end.

% Converts a binary representation of an integer into 
% a real integer, that is <<"123">> => 123
binary_to_integer(<<>>,Acc) -> Acc;
binary_to_integer(<<Num:8,Rest/binary>>,Acc) when Num >= 48 andalso Num < 58 ->
   binary_to_integer(Rest, Acc*10 + (Num-48));
binary_to_integer(_,Acc) -> exit({badarg,Acc}).

% Almost like takewhile, but for binaries
bin_takewhile(Char,Data) -> bin_takewhile1(Data,Char,<<>>).
bin_takewhile1(<<>>,_,Acc) -> Acc;
bin_takewhile1(<<Char,_Rest/binary>>,Char,Acc) -> Acc;
bin_takewhile1(<<Byte:8,Rest/binary>>,Char,Acc) -> 
   bin_takewhile1(Rest,Char,<<Acc/binary,Byte>>).
