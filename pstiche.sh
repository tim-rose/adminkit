#!/bin/sh
#
# PSTICHE.SH --Monitor the state of a system by dumping process data
#
# Remarks:
# This command runs a ps command within a delay loop
#
#. midden
#require log
#require getopt

usage="pstiche [-d delay] [-f format] command"
delay=60
values='pid,ppid,pid,user,pri,time,etime,pcpu,pmem,vsz,rss,comm'
date_format='%Y-%m-%dT%H:%M:%S '

#
# csv_formatter() --reformat text to CSV format, and pass to general formatter.
#
csv_formatter()
{
    sed -e 's/  */,/g'  | formatter
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
    \?)	echo $usage >&2
	exit 2;;
    esac
done
shift $(($OPTIND - 1))

#
# output header line
#
date_format="%s,%Y-%m-%d,%H:%M:%S,%z"
echo "epoch,date,time,zone,$values"

#
# main: sample process values via ps
#
while true; do
    ps ax -o "$values" |
        sed -e '1d' |			# remove header
	grep "$1" |			# filter on command
	sed -e "s/ *-*[^ ]*$1\$//" 	# remove command tag
#    break;
    sleep $delay
done | csv_formatter

