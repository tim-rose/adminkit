#!/bin/sh
#
# SSLOGIN --Login using ssh
#
# Remarks:
# This script is intended to be symlinked to the name of the host
# you wish to connect to.
#
host=$(basename $0)
if [ "$host" != 'sslogin' ]; then
    exec ssh $host $*
else
    exec ssh $*
fi
