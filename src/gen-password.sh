#!/bin/sh
#
# GEN-PASSWORD --Generate a random password
#
length=16
type='[A-Z][a-z][0-9]'
usage="Usage: gen-password [-n length] [-t type ]"

while getopts "n:t:" c
do
    case $c in
    n)  length=$OPTARG;;
    t)  type=$OPTARG;;
    \?)	echo $usage >&2
	exit 2;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 0 ]; then
    echo $usage >&2
    exit 2
fi

</dev/urandom tr -dc $type | head -c $length
printf "\n"
exit 0
