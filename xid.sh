#!/bin/bash

export TERM=vt100
{
/opt/Websense/bin/ConsoleClient localhost 15869 <<!EOF
2
1
3
/data/lists/websense_xid.txt
5
Q
!EOF
} > /dev/null

#+
#  cowro        2011.10.10
#-
