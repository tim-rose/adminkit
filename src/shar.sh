#!/bin/sh
# shar: shell archiver
#
# Contents:
# readlink()         --Define readlink(1) as needed...
# argv_or_stdin()    --output arguments (if specified) or lines from stdin.
# is_binary()        --Test if a file's content is "binary".
# is_missing_nl()    --Test if a file is missing a newline at end of file.
# archive_prologue() --Emit shar prologue.
# archive_dir()      --Emit archive code for a directory.
# archive_symlink()  --Emit archive code for a symlink.
# archive_file()     --Emit archive code for a plain file.
# main()             --Archive a list of files into a shell self-extracting archive
#
# Options:
# -d  --generate code to do a mkdir(1) if file is a directory.
# -e  --generate code to prevent overwriting existing files.
# -h  --follow symlinks
# -m  --encode binary files with base64 encoding (default is uuencode's default)
# -q  --avoid echo log messages (to stderr).
# -v  --echo log messages (to stderr).
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
# @todo: emit code that controls overwrite check when unpacking.
# @todo: emit code to unpack specified items.
#
options=dhmvq_
usage="Usage: shar -$options files... >archive"
mkdir_ok=
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
# argv_or_stdin() --output arguments (if specified) or lines from stdin.
#
# Remarks:
# This is an implementation of perl's behaviour wrt command arg.s
# and stdio.
#
argv_or_stdin()
{
    local arg

    if [ "$#" != "0" ]; then
	for arg; do echo "$arg"; done
    else
	while read arg; do
	    debug 'read arg: "%s"' "$arg"
	    echo "$arg"
	done
    fi
}


#
# is_binary() --Test if a file's content is "binary".
#
# Remarks:
# This is a simple test: does the file contain any non-printable ASCII.
# The non-printable characters allowed are:
# * \0	--utf16 bytes
# * \033 --colour formatting in log files etc.
# * \t\n.. --all the usual printf escapes
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
    cat <<- EOF
	#!/bin/sh
	# shell archive created on $(date)
	# by $USER@$(hostname)
	# from directory $PWD
	#
	# Contents:
	EOF
    for file; do
	echo "# $file"
    done
    echo "#"
    cat <<- 'EOF'
	force=
	tmpfile="shar-$$.tmp"
	trap "rm -f $tmpfile*" 0

	while getopts "f?" option
	do
	    case "$option" in
	    f)	force=1;;
	    \?)	echo "Usage: <file>.sh [-f] [files...]"  >&2
		exit 2;;
	    esac
	done
	shift $(($OPTIND - 1))

	match()
	{
	    local string="$1"
	    local pattern="$2"

	    case "$string" in
	    $pattern) return 0;;
	    esac
	    return 1
	}
	is_selected()
	{
	    local target="$1"; shift
	    if [ $# -eq 0 ]; then
	        return 0		# always selected
	    fi

	    for candidate; do
	        if match "$target" "$candidate"; then
	            return 0		# match
	        fi
	    done
	    return 1			# no matches
	}
	EOF
}


#
# archive_dir() --Emit archive code for a directory.
#
archive_dir()
{
    local file="$1"

    if [ "$mkdir_ok" ] ; then
	info "r %s\t(directory)" "$file"
	cat <<- EOF
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
    cat <<- EOF
	file_comment="symlink to $target"
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

    if [ "$dir" != '.' ]; then
	cat <<- EOF
	if [ ! -d "$dir" ]; then mkdir -p "$dir"; fi
	EOF
    fi

    if [ -s "$file" ]; then
	if is_binary "$file"; then
	    info 'r %s\t(binary file)' "$file"
	    echo 'file_comment="binary file"'
	    echo "cat > \"\$tmpfile.uu\" << '$eof_mark'"
	    uuencode $uu_opts "$file" < "$file"
	    echo "$eof_mark"
	    echo 'uudecode -o "$tmpfile" "$tmpfile.uu" && rm "$tmpfile.uu"'
	elif is_missing_nl "$file"  ; then
	    info 'r %s\t(missing-newline file)' "$file"
	    echo 'file_comment="missing newline"'
	    echo "sed -e 's/^# //' > \"\$tmpfile.nl\" << '$eof_mark'"
	    sed -e "s/^/# /" "$file"
	    printf "\n"		# add compensating newline
	    echo "$eof_mark"	# ...so eof mark is on a new line.
	    cat <<- EOF		# emit code to remove compensating newline
		file_size=\$(wc -c < "\$tmpfile.nl")
		dd ibs=1 count=\$((file_size-1)) < "\$tmpfile.nl" > "\$tmpfile" 2>/dev/null
		rm "\$tmpfile.nl"
		EOF
	else
	    info 'r %s' "$file"
	    echo 'file_comment="text file"'
	    echo "sed -e 's/^# //' > \$tmpfile << '$eof_mark'"
	    sed -e "s/^/# /" "$file"
	    echo "$eof_mark"
	fi
    else
	info 'r %s\t(empty file)' "$file"
	echo 'file_comment="empty file"'
	echo "touch \"\$tmpfile\""
    fi
}


#
# main() --Archive a list of files into a shell self-extracting archive
#
main()
{
    local status=0
    archive_prologue "$@"
    argv_or_stdin "$@" |
	{
	    while read file; do
		info 'archiving "%s"' "$file"
		status=0
		if [ -d "$file" ] ; then
		    archive_dir "$file" || status=1
		elif [ -h "$file" -a "$follow_symlink" ]; then
		    archive_symlink "$file" || status=1
		elif [ -f "$file" ]; then	# note: matches symlinks too
		    archive_file "$file" || status=1
		elif [ ! -e "$file" ]; then
		    notice 'r %s\tno such file (not archived)' "$file"
		    status=1
		else
		    notice 'r %s\tunsupported file type (not archived)' "$file"
		    status=1
		fi
		if [ "$status" -eq 0 ]; then
		    cat <<- EOF
			if is_selected "$file" "\$@"; then
			    if [ ! -e "$file" -o "\$force" ]; then
			        mv "\$tmpfile" "$file"
			    else
			        file_comment="file exists, not overwritten"
			    fi
			    printf 'x %s\t%s\n' '$file' "\$file_comment"
			fi
			EOF
		fi
	    done
	    exit "$status"
	}
    status=$?			# collect exit status from while loop
    #archive_epilogue
    return "$status"
}


while getopts "$options" opt
do
    case "$opt" in
    d)	mkdir_ok=1;;
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

main "$@"
