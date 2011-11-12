#!/bin/sh
#
# AGENT.SH --background task daemon, via make..
#
# Contents:
# usage()     --echo this script's usage message.
# run_parts() --Loggish version of run-parts.
#
# Remarks:
# This script wraps up the signal API of a daemon that can be
# defined by a makefile.
#
#
PATH=$PATH:/usr/libexec:/usr/local/libexec
. log.shl
. getopt.shl
. unit.shl

#
# usage() --echo this script's usage message.
#
usage()
{
    vcs_keyword 'agent.sh (unknown version)'
    getopt_usage "agent [options] directory" "$1"
}

#
# run_parts() --Loggish version of run-parts.
#
run_parts()
{
    if [ -d "$1" ]; then
    	info '%s: running commands' "$1"
	run-parts "$1"
    fi
}

opts="d.daemon;p.pid_file=;n.name=;w.wait=1d;$LOG_GETOPTS"
eval $(getopt_long_args -d "$opts" "$@" || usage "$opts" >&2)
log_getopts

if ! wait=$(opt_duration $wait); then
    exit 2;
fi

if [ ! "$1" ]; then
    err 'you must specify a directory'
    exit 2
fi
if [ ! -d "$1" ]; then
    err '%s: no such directory' "$1"
    exit 2
fi

. daemon.shl $name			# Go the Dees!
if [ "$daemon" ]; then
    daemonize $0 --name="$name" --pid-file="$pid_file" --wait="$wait" "$@"
    exit 0
fi

if [ "$name" ]; then
    LOG_IDENT="$name"
fi

if [ "$pid_file" ]; then
    begin_singleton "$pid_file"
fi

#
# setup signals
#
for sig in HUP INT QUIT ALRM TERM USR1 USR2; do
    info 'setting trap for %s' $sig
    trap "signal=$sig" $sig
done

#
# main loop...
#
# Remarks:
# This code just loops until interrupted by any of the signals, and
# calls run-parts to do the actual work.  If there's an
# interrupt-specific sub-dir, it is run too.
#
info '%s: starting' "$1"
while true; do
    signal=
    if ! snooze $wait; then
	case "$signal" in
	INT|QUIT|TERM)
	    notice 'signal %s: time to die' $signal
	    end_singleton
	    exit 1;;
	HUP)			# SIGHUP
	    info 'SIGHUP'
	    sigdir='hangup'
	    ;;
	ALRM)			# SIGALRM
	    info 'SIGALRM'
	    sigdir='alarm'
	    ;;
	USR1)			# SIGUSR1
	    info 'SIGUSR1'
	    sigdir='user1'
	    ;;
	USR2)			# SIGUSR2
	    info 'SIGUSR2'
	    sigdir='user2'
	    ;;
        *)  ;;
	esac
	run_parts "$1/$sigdir"
    fi
    run_parts "$1"
done
warning 'main loop exit'
end_singleton
exit 0
