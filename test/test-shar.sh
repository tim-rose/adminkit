#!/bin/sh
#
# test-errno --Tests for the errno command.
#
PATH=../src:/usr/local/lib/sh:$PATH
. tap.shl
plan 1

atexit rm out.sha

sh ../src/shar.sh no-such-file >out.sha

is "$?" "1" "fails for non-existing files"

#
# Test pack/unpack of:
# * text files
# * binary files
# * missing eol files
# * unsupported files
#
# * directory behaviour
# * symlink behaviour
# * overwrite behaviour
# * checksum behaviour
# * uuencode options
#
