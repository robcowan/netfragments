#!/bin/bash

xidstatus=$(grep "Timestamp: $(date +'%m-%d-%Y')" $xid_file_IN)
if [ -z "$xidstatus" ]
then
   mail -s "Check user identification" $email_TO < /dev/null > /dev/null
fi

#+
#  checkxid.sh           --  grep transparent user indentification file (xid) for current dates  --  cowro.2014.07.08
#-
