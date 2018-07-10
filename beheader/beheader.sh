#!/bin/sh

IFS=

while read -r LINE
do
    # Get length from header
    LENGTH=$(echo "$LINE" | sed -E 's/^Content-Length: ([0-9]+).*$/\1/')
    
    # Skip next line
    read -r LINE
    
    # Read JSON message, which is $LENGTH characters long
    read -r -n "$LENGTH" LINE
    
    printf "$LINE\r\n"
done
