#!/bin/bash
set -e

trap "kill -15 -1 && echo all proc killed" TERM KILL INT

if [ "$1" = "start" ]; then
	service apache2 start
	service mysql start
	service cron start 
	service voipmonitor start
	sleep inf & wait
else
	exec "$@"
fi
