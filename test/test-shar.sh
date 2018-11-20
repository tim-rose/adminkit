#!/bin/sh
#
# test-errno --Tests for the errno command.
#
PATH=:/usr/local/lib/sh:$PATH
. log.shl
. tap.shl

#
# setup, define teardown
#
plan 14
mkdir -p out
atexit rm -rf out.sha out

shar_archive()
(
    local dir="${1:-.}"; shift
    local root=$(echo "$dir" | sed -e 's|[^/]*|..|g')

    cd "$dir"
    log_cmd sh $root/../src/shar.sh "$@"
) >out.sha


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


shar_test()
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
# * unsupported files
# * "bad" names (e.g. w/ "bad file.txt"
#
(mkdir -p out && cd out && sh ../out.sha; rm -f out)
is "$(ls -a out | wc -l)" "2" "non-existent file: archive creates no file"

for file in $(cd data/file; find * -type f -o -type l); do
    shar_test "$file"
done


#
# * directory behaviour
# * symlink behaviour
# * overwrite behaviour
# * checksum behaviour
# * uuencode options
#
