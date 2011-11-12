#!/bin/sh
#
# db-dump --Export a database to a bunch of CSV files.
#
# Contents:
# usage() --echo this script's usage message.
#
PATH=$PATH:/usr/libexec:/usr/local/libexec

. log.shl
. getopt.shl

#
# usage() --echo this script's usage message.
#
usage()
{
    #vcs_keyword 'db-dump.sh (unknown version)'
    getopt_usage "db-export [options] [databases...]" "$1"
}

ignore_opts='i.ignore=mysql,*_schema,.*test.*'
db_opts="d.database=;h.host=;u.user=$USER;p.password="
opts="$db_opts;$ignore_opts;r.root=.;s.suffix=.sql;z.compress;$LOG_GETOPTS"

eval $(getopt_long_args -d "$opts" "$@" || usage "$opts" >&2)
log_getopts

#
# assemble mysql arguments...
#
mysql_args=
if [ "$user" ];     then mysql_args="$mysql_args -u$user"; fi
if [ "$password" ]; then mysql_args="$mysql_args -p$password"; fi
if [ "$host" ];     then mysql_args="$mysql_args -h$host"; fi

#
# guess databases if not provided
#
if [ $# -eq 0 ]; then
    if [ ! "$ignore" ]; then
	ignore='@@@'			# can't match?
    else
	ignore=$(echo "$ignore" | sed -e 's/,/|/g')
    fi
    debug "ignore: '%s'" "$ignore"
    databases=$(
        echo 
	mysql $mysql_args -e 'show databases' | 
	sed -e1d |
	egrep -v "$ignore")
else
    databases=$*
fi

#
# export each database...
#
for db in $databases ; do
    file="$root/$db$suffix"
    info 'dumping %s to %s' $db $file
    mkdir -p $(dirname $file)
    debug "mysqldump $mysql_args \"$db\" > $file"
    mysqldump $mysql_args "$db" > $file
    if [ "$compress" ]; then
	info 'compressing %s' $file
	gzip $file
    fi
done
