#!/bin/sh
#
# mkchroot --Create a chroot jail.
#
# Contents:
# usage() --echo this script's usage message.
#
# Remarks:
# This script creates a little directory hierarchy, and populates it
# with the specified commands.  It attempts to copy in all the shared-object
# libraries used by those commands too.  This is intended for setting up
# chroot jails for ftp, where the following setup should get you going:
# 
# # mkchroot -d -r ftproot ls more compress cpio gzip tar zcat
#
# Note: you'll need to be root to create the device files.
#
# If you are including the commands "id" or "group", they will need
# "/etc/nsswitch.conf", and related libnss-*.so libraries (which
# are loaded manually by these programs, and won't appear in "ldd").
#
# 
PATH=$PATH:/usr/libexec:/usr/local/libexec

. core.shl
require log.shl getopt.shl

#
# usage() --echo this script's usage message.
#
usage()
{
    vcs_keyword 'mkchroot.sh (unknown version)'
    getopt_usage "mkchroot [options] -r root commands..." "$1"
}

opts="d.dev;l.link;n.libnss;r.root=;u.user=;$LOG_GETOPTS"

eval $(getopt_long_args -d "$opts" "$@" || usage "$opts" >&2)
log_getopts

if [ ! "$root" ]; then
    echo "You must specify a root directory!" >&2
    exit 1
fi
if [ "$link" ]; then
    copy=ln
else
    copy=cp
fi

#
# create base directories and device files.
#
if [ ! -d $root ]; then
    info 'creating root directory: %s' $root
     mkdir $root ||
	log_quit 'failed to create root %s' $root
fi
for dir in bin dev etc lib; do
    mkdir -p $root/$dir
done
#
# Create the device files.
# REVISIT: consider creating a /dev/log FIFO so that chrooted users can syslog.
#
if [ "$dev" ]; then
    info 'creating device files'
    mknod $root/dev/null c 1 3 && chmod 666 $root/dev/null
    mknod $root/dev/zero c 1 5 && chmod 666 $root/dev/zero
    mknod $root/dev/urandom c 1 9 && chmod 666 $root/dev/urandom
    mknod $root/dev/tty c 5 0 && chmod 666 $root/dev/tty
fi

#
# create user, if specified.
#
if [ "$user" ]; then
    info 'adding passwd entry for %s' $user
    mkdir -p $root/ftp
    grep "^$user:" /etc/passwd >> $root/etc/passwd
fi
#
# We need to copy in the timezone data, otherwise the chrooted context
# is in UTC.
#
info 'copying system timezone files'
$copy /etc/timezone $root/etc/timezone
$copy /etc/localtime $root/etc/localtime

#
# import the specified commands into the chroot /bin directory
#
if [ ! "$*" ]; then
    exit 0			# no commands: just exit early
fi
info 'copying commands into bin'
for cmd in $*; do
    if [ ! -x $cmd ]; then
	cmd=$(which $cmd)
    fi
    if [ "$cmd" -a -x $cmd ]; then
	$copy $cmd $root/bin/$(basename $cmd)
    fi
done
#
# if a POSIX shell was one of the commands specified, make a link to sh.
# Note: these days a symlink is used, although a hard link would
# be better.
#
if [ ! -f $root/bin/sh ]; then
    if [ -x $root/bin/dash ]; then
	ln -s dash $root/bin/sh	# symlink dash -> sh
    elif [ -x $root/bin/bash ]; then
	ln -s bash $root/bin/sh # symlink bash -> sh
    fi
fi
#
# construct a list of libraries used by the commands we've imported...
#
libs=$(ldd $root/bin/* |
    fgrep .so.  |
    cut -f2     |
    grep /lib   |
    sed -e's/.* => //' -e's/ (0x.*//' |
    sort -u)
if [ "$libnss" ]; then
    libs="$libs $(find /lib -maxdepth 1 -type l -name 'libnss*')"
fi
for lib in $libs; do
    info 'copying library: %s' $lib
    dst=$root/$lib
    mkdir -p $(dirname $dst)
    if [ ! -f $dst ]; then
	$copy $lib $dst
    fi
done
