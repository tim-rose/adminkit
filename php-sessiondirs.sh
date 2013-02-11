#!/bin/sh
#
# PHP-SESSIONDIRS --Create the subdirectory structure needed for PHP sessions.
#
PATH=$PATH:/usr/libexec:/usr/local/libexec
. core.shl
require log.shl getopt.shl

prefix_chars="0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z"

#
# usage() --echo this script's usage message.
#
usage()
{
    getopt_usage "php-sessiondirs [-r root] [-n depth]" "$1"
}

opts="r.root=/var/lib/php;n.depth=3;$LOG_GETOPTS"

eval $(getopt_long_args -d "$opts" "$@" || usage "$opts" >&2)
log_getopts

#
# php_mkdirs() --Create a set of PHP session directories, recursively
#
php_mkdirs()
(
    local n=$(($2 - 1))
    if [ "$n" -ge 0 ]; then
	cd $1 || log_quit 'cannot change to directory "%s"' "$1"
	info "creating directories in \"%s\"" $PWD
	mkdir $prefix_chars
	for d in $prefix_chars; do
	    php_mkdirs $PWD/$d $n
	done
    fi
)

if [ ! -d $root ]; then
    info "creating root directory \"%s\"" $root
    mkdir -p $root
fi

php_mkdirs $root $depth
