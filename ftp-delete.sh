#!/bin/sh
#
# FTP-DELETE --delete some remote files via ftp.
#
# Contents:
# usage() --echo this script's usage message.
#
#
# Remarks:
# This file uses a heredoc to send the delete command to the remote
# system, and post-processes any errors into the standard logging facility..
# 
PATH=$PATH:/usr/libexec:/usr/local/libexec
. log.shl
. getopt.shl

#
# usage() --echo this script's usage message.
#
usage()
{
    vcs_keyword 'ftp-delete.sh (unknown version)'
    getopt_usage "ftp-delete -h host path..." "$1"
}

opts="h.host=;r.root=;$LOG_GETOPTS"

eval $(getopt_args -d "$opts" "$@" || usage "$opts" >&2)
shift $(($OPTIND - 1))
log_getopts

for host_path in $*; do
    status=0
    if match "$host_path" '*:*'; then
	this_host=$(echo $host_path|cut -d: -f1) # backward compatibility?
	this_path=$(echo $host_path|cut -d: -f2)
    else
	if [ ! "$host" ]; then
	    log_quit 'remote host is not defined'
	fi
	this_host=$host
	if [ "$root" ]; then
	    this_path=$root/$host_path
	else
	    this_path=$host_path
	fi
    fi
    info "ftp-delete[%s]: %s" $this_host $this_path
    {
	ftp $this_host <<EOF
delete $this_path
EOF
    } | 
    while read ftp_msg; do
	notice "ftp-delete[%s]: %s" $this_host "$ftp_msg";
	status=1
    done
done
exit $status
