#!/bin/sh
#
# BLOATFISH --Find, and kill processes using excessive resources.
#
PATH=$PATH:/usr/libexec:/usr/local/libexec
. log.shl

key=rss
key_max=$((580*1024))
delay=20
target=bash

#
# terminate_process() --Quietly terminate a process, by force if needed.
#
terminate_process()
{
    kill $1			# time to die...
    sleep $(($delay/2))
    if ps -p$1 >/dev/null 2>&1; then
	notice "force termination of process %d" $1
	kill -9 $1		# blast into low orbit and nuke it from space
    fi				# game over man!
}

#
# main...
#
debug "%s: start key=%s, key_max=%d" $(basename $0) $key $key_max
while true; do
    ps ax -o$key,pid,comm | sed -e1d | grep "$target" | 
    while read key_value pid command; do
	debug "%s/%d: %s=%d" "$command" $pid "$key" $key_value
	if [ $key_value -gt $key_max ]; then
	    notice "terminating %s/%d: %s=%d (>%d)" \
		"$command" $pid $key $key_value $key_max
	    terminate_process $pid &
	fi
    done
    sleep $delay
done
