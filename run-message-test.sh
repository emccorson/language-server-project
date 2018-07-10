#!/bin/sh
# Recount content length of all messages, escape CRLF and dump in messages.js

function recount() {
  LENGTH=$(sed -n '3,$p' "$1" | wc -c | sed -E 's/\s*(\S+)/\1/')
  sed -i -E "1 s/: (\S+)/: $LENGTH/" "$1"
}

function dump() {
  ESCAPED=$(cat "$1" | sed 's/\\n/\\\\n/g' | awk 'BEGIN { RS="\r\n"; ORS="\\\\r\\\\n"; } { print }')
  NAME=$(echo "$1" | sed -E 's#.*/([^/]+)#\1#')
  echo "const $NAME = '$ESCAPED';" >> "$DUMP"
}

MESSAGES="messages"
DUMP="message-test/messages.js"

cp /dev/null "$DUMP"

for i in "$MESSAGES"/*
do
  recount $i
  dump $i
done

echo "Done processing all files in ./messages.
Now open ./message-test/index.html in a browser to test sending messages."
