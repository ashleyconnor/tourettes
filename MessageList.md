This contains a list of all messages that are accepted in the tracker, and where. <br />

torr\_client: <br />
**{parse\_ok,Dict} - Sent from the parser**<br />
**parse\_fail - Sent from the parser**<br />
**{peers,PeerDict} - Sent from the tracker**<br />
**fail - Sent from the tracker**<br />
<br />
torr\_tracker:<br />
**{request,{Pid,ReqDict}} - Sent from the client**<br />
**{add,Hash} - Just for testing**<br />