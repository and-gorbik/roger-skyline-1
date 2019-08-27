#!/bin/bash

PREV="/root/crontab"
EMAIL="root@debian"

if [ -e $PREV ]
then
	DIFF=$(diff /etc/crontab $PREV)
	if [ "$DIFF" ]
	then
		cat /etc/crontab | mail -s "Crontab was modified!" $EMAIL
	fi
fi
cat /etc/crontab > $PREV
