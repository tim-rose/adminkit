#!/bin/sh
#
# PROCWATCH.SH --watch a process's usage of cpu and memory.
#
# Remarks:
# This command runs a ps command within a delay loop, and (re-prints)
# the system stats for the specified process.
#
PATH=$PATH:/usr/libexec:/usr/local/libexec

. core.shl
require log.shl

usage="procwatch [-d delay] [-f format] command"
delay=60
format=ps
values='pid,ppid,pid,user,pri,start,time,etime,pcpu,pmem,vsz,rss,command'
date_format='%Y-%m-%dT%H:%M:%S '
formatter='formatter'

#
# csv_formatter() --reformat text to CSV format, and pass to general formatter.
#
csv_formatter()
{
    sed -e 's/  */,/g' | formatter
}

#
# formatter() --Format text to lines with a timestamp.
#
formatter()
{
    while read line; do
	date "+$date_format$line"
    done
}

#
# options...
#
while getopts "d:f:" c
do
    case $c in
    d)  delay=$OPTARG;;
    f)  format=$OPTARG;;
    \?)	echo $usage >&2
	exit 2;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 1 ]; then
    echo 'You must specify a command to watch!'
    echo $usage >&2
    exit 2
fi

#
# output header line, check format type
#
if [ "$format" = 'ps' ]; then
    ps -eo $values | sed -e '2,$d' -e 's/^/TIMESTAMP           /'
elif [ "$format" = 'csv' ]; then
    date_format="%s,%Y-%m-%d,%H:%M:%S,%z"
    formatter='csv_formatter'
    echo "epoch,date,time,zone,$values"
else
    echo "cannot understand format \"$format\".  Must be \"ps\" or \"csv\""
    echo $usage >&2
    exit 2
fi

#
# main: sample process values via ps
#
while true; do
    ps ax -o "$values,comm" |
        sed -e '1d' |			# remove header
	grep "$1" |			# filter on command
	sed -e "s/ *-*[^ ]*$1\$//" 	# remove command tag
    sleep $delay
done | $formatter			# format for display (csv or ps)

