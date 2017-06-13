#!/bin/sh
#
# TINT --decorate a program's output with some colour.
#
# Usage:
# tint [-s style] <command> <arg.s>
#
# Remarks:
# Tint adjusts the output of a command using ANSI X3.64 control sequences.
# By default it detects the style to use from the command, but this
# can be overridden with the "-s" option.
#
#
. midden
require log

style="$1"
if [ -e "$TINTPATH/$style.conf" ]; then
    :
    # adjust style to user's settings
    # apply style using sed?
    # Profit!
fi

log_quit 'not implemented'
