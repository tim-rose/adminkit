#!/bin/sh
#
# test-shar --Tests for the shar command.
#
# Contents:
# shar_archive() --Create a shar archive from a data directory.
# check_files()  --Check that the unpacked files match the originals.
# check_shar()   --Perform a suite of tests on a shar.
#
PATH=:/usr/local/lib/sh:$PATH
. log.shl
. tap.shl

#
# setup, define teardown
#
mkdir -p out
atexit rm -rf out.sha out files.txt

#
# shar_archive() --Create a shar archive from a data directory.
#
# Parameter:
# dir --the directory containing files/subdirs to archive
#
# Remarks:
# The archive is written as "out.sha".
#
shar_archive()
(
    local dir="${1:-.}"; shift
    local root=$(echo "$dir" | sed -e 's|[^/]*|..|g')

    cd "$dir"
    log_cmd sh $root/../src/shar.sh -q "$@"
) >out.sha


#
# check_files() --Check that the unpacked files match the originals.
#
check_files()
{
    local src="$1"; shift
    local file= status=0

    for file; do
    	debug 'comparing "%s"' "$file"
    	if ! cmp "out/$file" "$src/$file"; then
    	    echo "$file"
    	    status=1
    	fi
    done
    rm -rf out
    exit $status
}


#
# check_shar() --Perform a suite of tests on a shar.
#
check_shar()
{
    local file="$1"
    shar_archive data/file "$file"
    is "$?" "0" '%s: shar command succeeds' "$file"
    mkdir -p out
    files=$(cd out && sh ../out.sha | sed -e 's/^x //' -e 's/\t.*//')
    is "$(check_files data/file "$files")" "" '%s: target matches source' "$file"
}


#
# handle non-existent files.
#
shar_archive data/file 'no-such-file.txt'
isnt "$?" "0" "non-existent file: shar command fails"

#
# Test pack/unpack of:
# * text files
# * binary files
# * missing eol files
#
(mkdir -p out && cd out && sh ../out.sha; rm -f out)
is "$(ls -a out | wc -l)" "2" "non-existent file: archive creates no file"

(cd data/file; find * -type f -o -type l) > files.txt
    while read file; do
	check_shar "$file"
    done < files.txt

#
# @todo: unsupported files (char special, fifo?)
# @todo: directory behaviour
# @todo: symlink behaviour
# @todo: overwrite behaviour
# @todo: uuencode options
# @todo: file list from stdin
#
plan
