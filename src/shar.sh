#!/bin/sh
# shar: shell archiver
#
# Parameters:
# -b (if present) --archive under basename only.
# -c (if present) --generate code to perform wc(1)-based checksums.
# -d (if present) --generate code to do a mkdir(1) if file is a directory.
# -e (if present) --generate code to prevent overwriting existing files.
# -v (if present) --echo log messages to stderr.
# arg1...argn	--files to be archived
#
# Discussion:
# shar provides a simple, portable machanism for archiving text files
# intended for distribution. The archive is printed to <stdout>, and
# may be redirected as required. All diagnostics are printed to
# <stderr>.
#
# The archive created by shar may be unpacked by running it as a
# Bourne shell script.
# REVISIT: test last char of file with tail -c1 (must be newline!)
#
OPTS=bcdev
usage="Usage: shar -$OPTS files... >archive"
BFLAG=
CFLAG=
DFLAG=
EFLAG=
verbose=

log_message() { printf "$@"; printf "\n"; } >&2
notice()      { log_message "$@"; }
info()        { if [ "$verbose" ]; then log_message "$@"; fi; }
debug()       { if [ "$debug" ]; then log_message "$@"; fi; }
log_quit()    { notice "$@"; exit 1 ; }


#
# prologue() --emit shar prologue.
#
prologue()
{
    cat <<-EOF
	#!/bin/sh
	# shell archive created on $(date)
	# by $USER@$(hostname) from directory $PWD
	#
	EOF
}

main()
{
    for file; do
	if [ BFLAG = 1 ] ; then
	    file=$(basename $file)
	fi
	if [ -d $file ] ; then
	    if [ !"$DFLAG" ] ; then
		notice "%s: directory	(not archived)" "%file"
	    else				# generate code to make a directory
		echo "if [ ! -d $file ] ; then mkdir $file; fi"
	    fi
	elif [ -f $file ]; then
            info "r %s" "$file"
	    EOFMARK="[@-$(basename $file)-EOF]"
	    if [ $EFLAG = 0 ] ; then
		echo "echo x $file"
		echo "cat > $file << '$EOFMARK'"
	    else				# generate code to stop file overwrites
		echo "if [ -f $file ] ; then"
		echo "    echo \"$file: exists	(not unarchived)\""
		echo "    FILE=/dev/null"
		echo "else"
		echo "    echo x $file"
		echo "    FILE=$file"
		echo "fi"
		echo "cat > \$FILE << '$EOFMARK'"
	    fi
	    cat $file
	    echo $EOFMARK
	    if [ $CFLAG = 1 ] ; then	# generate code to perform checksums
		CHECK=$(wc -lwc $file|sed -e "s/  */ /g")
		LINES=$(echo $CHECK|cut -f1 -d' ')
		WORDS=$(echo $CHECK|cut -f2 -d' ')
		CHARS=$(echo $CHECK|cut -f3 -d' ')
		echo "set \$(wc -lwc <$file) 0 0 0"
		echo "if [ \$1\$2\$3 != $LINES$WORDS$CHARS ] ; then"
		echo "echo Checksum error: wc results of $file are \$*. should be $LINES $WORDS $CHARS >&2"
		echo "fi"
	    fi
	fi
    done
}

while getopts $OPTS c
do
    case $c in
    b)	BFLAG=1;;
    c)	CFLAG=1;;
    d)	DFLAG=1;;
    e)	EFLAG=1;;
    v)	verbose=1;;
    \?)	echo $usage >&2
	exit 2;;
    esac
done
shift $(($OPTIND - 1))

if [ $# = 0 ] ; then
    echo $usage >&2
    exit 2
fi
if [ $BFLAG = 1 ] ; then
    DFLAG=0				# -d and -b considered incompatible
fi

main "$@"
