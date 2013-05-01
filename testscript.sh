#!/bin/sh

while true; do
  request_string="GET /announce?info_hash=0123456789012345678\
%$(printf %02X $(( $RANDOM & 0xf )) )&peer_id="abcdefKUK"&uploaded=0&downloaded=0&left=0\
&ip=$(( $RANDOM & 0xf )).$(( $RANDOM & 0xf )).13.16&port=$(( $RANDOM & 0xff )) HTTP/1.0\r\n"

echo $request_string
#  echo
  echo $request_string | nc 129.16.25.146 60666 >/dev/null
#  echo

done
