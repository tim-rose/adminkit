#!/bin/sh
#
# db-export --Export some databases to (possibly compressed) SQL.
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
db_opts="h.host=;u.user=$USER;p.password="
opts="$db_opts;$ignore_opts;r.root=.;s.suffix=.sql;m.message=;z.compress;$LOG_GETOPTS"

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
    debug "db-export: ignore pattern: '%s'" "$ignore"
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
    date "+-- db-export: started at %Y-%m-%d %H:%M:%S %Z" >$file
    if [ "$message" ]; then
	echo "$message" | sed -e 's/^/-- db-export: /' >> $file
    fi
    if ! mysqldump $mysql_args "$db" >> $file; then
	fatal 'db-export: failed to connect to database server'
	rm -f $file
	exit 1;
    fi
    date "+-- db-export: completed at %Y-%m-%d %H:%M:%S %Z" >>$file
    if [ "$compress" ]; then
	info 'compressing %s' $file
	gzip $file
    fi
done
