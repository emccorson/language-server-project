Dear brave implementer,

This is all my progress in the language server project. It is now in your hands. Good luck.


Outline
=======

              Language server request
              wrapped in WebSocket
              message e.g.
              
              Content-Length: ...\r\n               Same request but 
              \r\n                                  as TCP instead of
              { "jsonrpc": "2.0", ... }             WebSocket                        No change
    
    +--------+                        +------------+                 +-------------+                    +--------+
    |        |----------------------->|            |---------------->|             |------------------->|        |
    | CLIENT |                        | websockify |                 | beheader.sh |                    | SERVER |
    |        |<-----------------------|            |<----------------|             |<-------------------|        |
    +--------+                        +------------+                 +-------------+                    +--------+
     
              Server response wrapped               Server response                 Language server
              in WebSocket message                  with header                     response in TCP message
              with binary payload                   part removed e.g.               e.g.

                                                    { "jsonrpc": "2.0", ... }       Content-Length: ...\r\n
                                                                                    \r\n
                                                                                    { "jsonrpc": "2.0", ... }


There are four parts to the project:

1. __The Monaco client__  
   The client sends and receives WebSocket messages.

2. __websockify__  
   websockify receives WebSocket messages from the client, translates them to plain TCP, then sends them to the server,
   and vice versa. You should use the Node version of this program, not the Python one. (I couldn't get the Python one
   to work and neither could a lot of people online.)

3. __beheader.sh__  
   beheader.sh is a shell script that receives messages from the server, removes the header part, and sends the
   remaining JSON part to the client. This is necessary because the client doesn't accept messages that have the header
   part, even though this is part of the language server spec. :(

4. __The language server__  
   A normal language server. Works with TCP or stdio. I've been using the TCP version.


Building
========

1. `git submodule init && git submodule update`
2. `cd websockify/other/js && npm install`
3. `cd javascript-typescript-langserver && npm install && npm run build`
4. `cd vscode-ws-jsonrpc && npm install`
5. `cd monaco-languageclient && npm install && cd example && npm install`


Running
=======

1. Run `./run-language-server.sh` to start the language server.
2. Wait until the language server is listening for connections then run `./run-beheader.sh` in a new terminal.
3. Run `./run-websockify.sh` in a new terminal to start websockify.
4. Run `./run-client.sh` in a new terminal to start the client.
5. Navigate to `localhost:3000` in a browser window. You should be able to see the messages sent and received in the
   output of `./run-language-server.sh`.


Files
=====

./run-language-server.sh
------------------------
Starts the language server listening on port 2000.

./run-beheader.sh
-----------------
Starts `beheader.sh`. Proxies between language server on port 2000 and WebSocket traffic on port 2003.

./run-websockify.sh
-------------------
Starts websockify. Listens for WebSocket traffic on `ws://localhost:2089`.

./run-client.sh
---------------
Starts the example Monaco client. Access it in a browser window at `localhost:3000`.

./messages
----------
A collection of messages that are valid per the language server protocol and will also be accepted by the language
server.

These files all use CRLF line endings because that's what the protocol specifies.

If you change the body of a message, the `Content-Length` header will need updated. You can do this automatically by
running `./run-message-test.sh`.

./run-message-test.sh
---------------------
Use this to manually test sending messages over WebSocket to the language server. This script processes all the messages
in `./messages` and dumps them in `./message-test/messages.js`. If you make any changes to the messages, you need to
rerun this command. After running this script, you can test messages by opening `./message-test/index.html` in a
browser window.

./message-test/index.html
-------------------------
Open it in a browser to manually send messages to the language server. You need to run `./run-message-test.sh` first.


Problems you might run into
===========================

Client doesn't send or accept header part of message
----------------------------------------------------
Language server messages should have a header part (usually just `Content-Length`) and a JSON body
(https://microsoft.github.io/language-server-protocol/specification).

However, the client only sends and accepts messages without the header part. Therefore outgoing messages need to have
the header part added, and incoming messages need to have the header part removed.

I've added a hack to add the header part to outgoing messages to the client itself. The only required header is
`Content-Length` so my fix counts the length of the outgoing message and then prefixes that as a header.

Incoming messages have their header part removed by `beheader.sh`.

Client receives binary data
---------------------------
WebSocket frames can have a text or binary payload, depending on the frame's opcode
(https://datatracker.ietf.org/doc/rfc6455/).

For some reason the client only supports text payloads. It assumes the payload is a string and then crashes if it is
actually a Blob. I've opened an issue on the appropriate library's GitHub
(https://github.com/TypeFox/vscode-ws-jsonrpc/issues/7).

websockify appears to always send WebSocket frames with a binary payload, and I can't find any option to send a text
payload instead.

I've put a quick fix in `vscode-ws-jsonrpc`.

Server responses don't end in a newline
---------------------------------------
Responses sent by the server do not end with a newline character.

This means tools that process input per line, such as `sed` and `read` (by default), won't work.

To manually read a message from the server, you'll need to read the length of the message from the `Content-Length`
header, then read that number of characters from the JSON part. `beheader.sh` shows how to do this.

Some valid requests crash the server
------------------------------------
The server throws an error when it doesn't like a request, even if it's a valid request per the language server
specification.

Unfortunately, the error messages are completely useless. It's usually something along the lines of "tried to access
some property on an object but the object is undefined so it didn't work".

There is a collection of messages the server will accept in `./messages` which might help you out.

Otherwise, ask for help on [Gitter](https://gitter.im/sourcegraph/javascript-typescript-langserver).
