#!/bin/sh

BEHEADER_DIR=./beheader
FIFO=fifo

if [[ ! -p $FIFO ]]
then
  mkfifo $BEHEADER_DIR/$FIFO
fi

ncat -k -l -p 2003 <$BEHEADER_DIR/$FIFO | nc 127.0.0.1 2000 | "$BEHEADER_DIR/beheader.sh" >$BEHEADER_DIR/$FIFO
