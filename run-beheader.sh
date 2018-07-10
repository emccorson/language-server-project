#!/bin/sh

BEHEADER_DIR=./beheader

ncat -k -l -p 2003 <$BEHEADER_DIR/fifo | nc 127.0.0.1 2000 | "$BEHEADER_DIR/beheader.sh" >$BEHEADER_DIR/fifo
