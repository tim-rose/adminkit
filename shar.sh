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
#
OPTS=bcdev
USAGE="Usage: shar -$OPTS files... >archive"
BFLAG=0
CFLAG=0
DFLAG=0
EFLAG=0
VFLAG=0

while getopts $OPTS c
do
    case $c in
    b)	BFLAG=1;;
    c)	CFLAG=1;;
    d)	DFLAG=1;;
    e)	EFLAG=1;;
    v)	VFLAG=1;;
    \?)	echo $USAGE >&2
	exit 2;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# = 0 ] ; then
    echo $USAGE >&2
    exit 2
fi
if [ $BFLAG = 1 ] ; then
    DFLAG=0				# -d and -b considered incompatible
fi
echo "#!/bin/sh"
echo "# shell archive created on `date`"
echo "# by $USER@`hostname` from directory `pwd`"
echo "#"
for file in $*
do
    if [ BFLAG = 1 ] ; then
	file=`basename $file`
    fi
    if [ -d $file ] ; then
	if [ $DFLAG = 0 ] ; then
	    echo "$file: directory	(not archived)" >&2
	else				# generate code to make a directory
	    echo "if [ ! -d $file ] ; then mkdir $file; fi"
	fi
    elif [ -f $file ]
    then
	if [ $VFLAG = 1 ] ; then	# let bozo know what's happening
	    echo r $file >&2
	fi
	EOFMARK="[@-`basename $file`-EOF]"
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
	    CHECK=`wc -lwc $file|sed -e "s/  */ /g"`
	    LINES=`echo $CHECK|cut -f1 -d' '`
	    WORDS=`echo $CHECK|cut -f2 -d' '`
	    CHARS=`echo $CHECK|cut -f3 -d' '`
	    echo "set \`wc -lwc <$file\` 0 0 0"
	    echo "if [ \$1\$2\$3 != $LINES$WORDS$CHARS ] ; then"
	    echo "echo Checksum error: wc results of $file are \$*. should be $LINES $WORDS $CHARS >&2"
	    echo "fi"
	fi
    fi
done
exit 0
