#!/bin/sh
#
# ERRNO --Report information about a system error.
#
# Remarks:
# This works by grepping the data from a "C" language include file
# from the standard library.  That's admittedly a pretty dirty trick,
# but, meh.
#
PATH=$PATH:/usr/lib/sh:/usr/local/lib/sh

. midden
require log
require getopt

errno_file="/usr/include/sys/errno.h"
opts="f.errno_file=$errno_file;$LOG_GETOPTS"

eval $(
    getopt_args -d "$opts" "$@" ||
    getopt_usage "errno [-f <errno_file>] error..." "$opts" >&2
)
shift $(($OPTIND - 1))
log_getopts

#
# main() --print error information for each argument.
#
main()
{
    if [ ! -e "$errno_file" ]; then
	log_quit 'cannot open error definitions file "%s"' "$errno_file"
    fi
    for arg; do
	print_errno "$arg"
    done
}

#
# print_errno() --Print the error(s) that "match".
#
# Remarks:
# The match criteria is a little quirky; it looks for an exact match
# on the number and code fields, but will match anything in the
# description.
#
# Hopefully, in most cases this is the "right thing".
#
print_errno()
{
    local error=$1

    if [ "$error" ]; then
        sed -ne '/^#define/s/^#define//p' <$errno_file |
            while read code number description; do
		match "$description" "*$error*"
		if [ $? -eq 0 -o "$error" = "$code" -o "$error" = "$number" ]; then
                    description=${description%% [*]/} # strip comment delimtiters
                    description=${description##/[*]}
                    printf '%3d: %-10s %s\n' "$number" "$code" "$description"
		fi
            done
    fi
}

main "$@"
