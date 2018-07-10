#!/bin/sh

SERVER_DIR=./javascript-typescript-langserver
PORT="2000"

node $SERVER_DIR/lib/language-server.js -p "$PORT" -t
