#!/bin/sh
#
# PHP-SESSIONDIRS --Create the subdirectory structure needed for PHP sessions
#
PATH=$PATH:/usr/libexec:/usr/local/libexec

. core.shl
require log.shl

root=php-session
depth=3
prefix_chars="0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z"

php_mkdirs()
(
    local n=$(($2 - 1))
    if [ "$n" -ge 0 ]; then
	cd $1
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
