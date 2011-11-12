#!/bin/sh
#
# FTP-UPLOAD --upload some files to a server via ftp.
#
# Contents:
# usage()      --echo this script's usage message.
# ftp_cmd()    --Run an FTP command, and log any messages.
# ftp_mkpath() --Make a directory path on a remote server
#
# Remarks:
# This file uses a heredoc to send the upload command to the remote
# system, and post-processes any errors into the standard logging facility..
# 
# 
PATH=$PATH:/usr/libexec:/usr/local/libexec

. log.shl
. getopt.shl

#
# usage() --echo this script's usage message.
#
usage()
{
    vcs_keyword 'ftp-upload.sh (unknown version)'
    getopt_usage "ftp-upload [options] -h host path..." "$1"
}

#
# ftp_cmd() --Run an FTP command, and log any messages.
#
ftp_cmd() 
{
    _host=$1; shift 1;
    debug 'ftp_cmd[%s]: %s' $_host "$*"
    {
	ftp -p $_host <<EOF
$*
EOF
    } | 
    while read ftp_msg; do
	info "ftp-cmd[%s-%s]: %s" $_host "$*" "$ftp_msg";
	false
    done
}

#
# ftp_mkpath() --Make a directory path on a remote server
#
ftp_mkpath()
{
    base=
    for d in $(echo $1 | sed -e 's|/| |'); do
	if [ "$d" = '.' ]; then
	    continue
	fi
	if [ "$base" ]; then
	    base="$base/$d"
	elif [ "$root" ]; then
	    base=$root/$d
	else
	    base=$d
	fi
	ftp_cmd $host mkdir $base
    done
}

#
# main...
#
opts="d.delete;h.host=;r.root=;$LOG_GETOPTS"

eval $(getopt_args -d "$opts" "$@" || usage "$opts" >&2)
shift $(($OPTIND - 1))
log_getopts

for path in $*; do
    ftp_mkpath $(dirname $path)
    if [ "$root" ]; then
	remote_path=$root/$path
    else
	remote_path=$path
    fi
    info "ftp-upload[%s]: %s" $host $path
    ftp_cmd $host put $path $remote_path
    if [ $? -eq 0 -a "$delete" ]; then
	info '%s: removing local copy' $path
	rm $path
    fi
done
