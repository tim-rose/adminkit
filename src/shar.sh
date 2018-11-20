#!/bin/sh
# shar: shell archiver
#
# Contents:
# readlink()           --Define readlink(1) as needed...
# is_binary()          --Test if a file's content is "binary".
# is_missing_nl()      --Test if a file is missing a newline at end of file.
# archive_prologue()   --Emit shar prologue.
# archive_checksum()   --Emit code to check the file integrity.
# archive_overwrite_check() --Emit archive code to check for file overwrites.
# archive_dir()        --Emit archive code for a directory.
# archive_symlink()    --Emit archive code for a symlink.
# archive_file()       --Emit archive code for a plain file.
# main()               --Archive a list of files into a shell self-extracting archive
#
# Options:
# -c  --generate code to perform wc(1)-based checksums.
# -d  --generate code to do a mkdir(1) if file is a directory.
# -e  --generate code to prevent overwriting existing files.
# -h  --follow symlinks
# -m  --encode binary files with base64 encoding
# -v  --echo log messages to stderr.
# arg1...argn	--files to be archived
#
# Remarks:
# shar provides a simple, portable machanism for archiving text files
# intended for distribution. The archive is printed to <stdout>, and
# may be redirected as required. All diagnostics are printed to
# <stderr>.
#
# The archive created by shar may be unpacked by running it as a
# Bourne shell script.
#
# @revisit: overwriting code is messy and buggy.
#
options=cdehmvq_
usage="Usage: shar -$options files... >archive"
checksum_ok=
mkdir_ok=
overwrite_ok=1
follow_symlink=1
uu_opts=
quiet=
verbose=
debug=

log_message()	{ printf "$@"; printf "\n"; } >&2
notice()	{ if [ ! "$quiet" ]; then log_message "$@"; fi; }
info()		{ if [ "$verbose" ]; then log_message "$@"; fi; }
debug()		{ if [ "$debug" ]; then log_message "$@"; fi; }
log_cmd()	{ debug "exec: %s" "$*"; "$@"; } >&2
log_quit()	{ notice "$@"; exit 1 ; }

#
# readlink() --Define readlink(1) as needed...
#
if ! type readlink >/dev/null 2>&1; then
    debug 'emulating readlink(1)'
    readlink()
    {
	local file="$1"
	if [ -h "$1" ]; then
	    ls -l "$1" | sed -e 's/.* -> //'
	    true
	else
	    false
	fi
    }
fi


#
# is_binary() --Test if a file's content is "binary".
#
# Remarks:
# This is a simple test: does the file contain any non-printable ASCII.
#
is_binary()
{
    local file="$1"
    n=$(tr -d '\000\033\a\b\t\r\n\f\v !-~' <"$file" | wc -c)
    if [ "$n" -ne 0 ]; then
	debug '%s: contains %d unprintable characters' "$file" "$n"
	true
    else
	false
    fi
}


#
# is_missing_nl() --Test if a file is missing a newline at end of file.
#
is_missing_nl()
{
    local file="$1"

    test "$(tail -c1 "$file")" != ""
}


#
# archive_prologue() --Emit shar prologue.
#
archive_prologue()
{
    cat <<-EOF
	#!/bin/sh
	# shell archive created on $(date)
	# by $USER@$(hostname) from directory $PWD
	#
	# Contents:
	EOF
    for file; do
	echo "# $file"
    done
    echo "#"
}


#
# archive_checksum() --Emit code to check the file integrity.
#
archive_checksum()
{
    local file="$1"
    local check=$(wc -lwc <$file | sed -e 's/^ *//' -e 's/  */-/g')
    cat <<-EOF
	if [ "\$local_file" = "$file" ]; then
	    set \$(wc -lwc < "$file") 0 0 0
	    if [ "\$1-\$2-\$3" != $check ] ; then
	        file_comment="checksum error: \$1-\$2-\$3. Should be $check."
	    fi
	fi
	EOF
}


#
# archive_overwrite_check() --Emit archive code to check for file overwrites.
#
archive_overwrite_check()
{
    if [ ! "$overwrite_ok" ]; then
	cat <<-EOF
	if [ -f "$file" ]; then
	    file_comment="file exists, not overwritten"
	    local_file="/dev/null"
	fi
	EOF
    fi
}


#
# archive_dir() --Emit archive code for a directory.
#
archive_dir()
{
    local file="$1"

    if [ "$mkdir_ok" ] ; then
	info "r %s\t(directory)" "$file"
	cat <<-EOF
	file_comment="directory"
	if [ ! -d $file ]; then mkdir \"$file\"; fi
	EOF
    else				# emit code to make a directory
	notice "%s:\t(directory	(not archived)" "$file"
    fi
}


#
# archive_symlink() --Emit archive code for a symlink.
#
# Remarks:
# The symlink target is not checked; it might be utterly broken
# (although hopefully not when unpacked).
#
archive_symlink()
{
    local file="$1" target="$(readlink "$file")"
    local dir=$(dirname "$file") base=$(basename "$file")

    info "r %s\t(symlink)" "$file"
    archive_overwrite_check
    cat <<-EOF
	file_comment="\${file_comment:-symlink to $target}"
	(cd "$dir" && ln -sf "$target" "$base")
	EOF
}


#
# archive_file() --Emit archive code for a plain file.
#
# Remarks:
# There a several special cases here:
# * a "text" file
# * a "binary" file
# * a symlink
# * an empty file
# * a text file with a missing newline at end-of-file
#
# @revisit: Save to temp file, then move if check-sum/exists check OK.
#
archive_file()
{
    base=$(basename "$file")
    dir=$(dirname "$file")
    eof_mark="[EOF@$file]"

    info "r %s" "$file"
    cat <<-EOF
	if [ ! -d "$dir" ]; then mkdir -p "$dir"; fi
	local_file="$file"
	EOF
    archive_overwrite_check

    if [ -s "$file" ]; then
	if is_binary "$file"; then
	    info 'r %s\t(binary file)' "$file"
	    echo "cat > $base.uu << '$eof_mark'"
	    uuencode $uu_opts "$file" <"$file"
	    echo "$eof_mark"
	    echo "uudecode -o \"\$local_file\" \"$base.uu\" && rm \"$base.uu\""
	    echo 'file_comment="${file_comment:-binary file}"'
	elif is_missing_nl "$file"  ; then
	    info 'r %s\t(missing-newline file)' "$file"
	    echo "sed -e 's/^# //' > \$local_file << '$eof_mark'"
	    sed -e "s/^/# /" "$file"
	    printf "\n"		# add compensating newline
	    echo "$eof_mark"	# ...so eof mark is on a new line.
	    cat <<-EOF		# emit code to remove compensating newline
		file_size=\$(wc -c < "$file")
		dd ibs=1 count=\$((file_size-1)) < "$file" > "$file.nl" 2>/dev/null
		mv "$file.nl" "$file"
		EOF
		echo 'file_comment="${file_comment:-missing newline}"'
	else
	    info 'r %s' "$file"
	    echo "sed -e 's/^# //' > \$local_file << '$eof_mark'"
	    sed -e "s/^/# /" "$file"
	    echo "$eof_mark"
	    echo 'file_comment="${file_comment:-text file}"'
	fi
	if [ "$checksum_ok" ] ; then
	    archive_checksum "$file"
	fi
    else
	info 'r %s\t(empty file)' "$file"
	echo 'file_comment="${file_comment:-empty file}"'
	echo "touch \"$file\""
    fi
}


#
# main() --Archive a list of files into a shell self-extracting archive
#
main()
{
    archive_prologue "$@"
    for file; do
	echo "printf 'x %s' '$file'"
	echo "file_comment="
	if [ -d "$file" ] ; then
	    archive_dir "$file"
	elif [ -h "$file" -a  "$follow_symlink" ]; then
	    archive_symlink "$file"
	elif [ -f "$file" ]; then	# note: matches symlinks too
	    archive_file "$file"
	elif [ ! -e "$file" ]; then
	    notice 'r %s\tno such file (not archived)' "$file"
	else
	    notice 'r %s\tunsupported file type (not archived)' "$file"
	fi
	echo "printf '\\\\t%s\\\\n' \"\$file_comment\""
    done
    #archive_epilogue
}

while getopts "$options" opt
do
    case "$opt" in
    c)	checksum_ok=1;;
    d)	mkdir_ok=1;;
    e)	overwrite_ok=;;
    h)	follow_symlink=;;
    m)  uu_opts='-m';;
    v)	quiet= verbose=1 debug=;;
    q)	quiet=1 verbose= debug=;;
    _)	quiet= verbose=1 debug=1;;
    \?)	echo $usage >&2
	exit 2;;
    esac
done
shift $(($OPTIND - 1))

if [ "$#" -eq 0 ] ; then
    echo $usage >&2
    exit 2
fi

main "$@"
