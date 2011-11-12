#!/bin/sh -
#
# LESSPIPE --less input filter
#
# Remarks:
# To use this filter with less, define LESSOPEN:
# export LESSOPEN="|/usr/bin/lesspipe.sh %s"
# 
lesspipe()
{
    case "$1" in			# resolve "cat"-like displayer
    *.[zZ]|*.gz) cat="gzip -dc" ;;
    *.bz2) 	cat="bzip2 -dc" ;;
    *) 		cat="cat" ;;
    esac

    case "$1" in
    *.[1-9n]|*.man|*.[1-9n].bz2|*.man.bz2|*.[1-9].gz|*.[1-9]x.gz|*.[1-9].man.gz)
	    if $cat -- "$1" | file - | grep -q troff; then
		if echo "$1" | grep -q ^/; then	#absolute path
			man -- "$1" | cat -s
		else
			man -- "./$1" | cat -s
		fi
	    else
		$cat -- "$1"
	    fi
	    ;;
	*.pod)
	    pod2man "$1" | nroff -man | cat -s
	    ;;
	*.tar)
	    tar tvvf "$1"
	    ;;
	*.tgz|*.tar.gz|*.tar.[zZ])
	    tar tzvvf "$1"
	    ;;
	*.tar.bz2|*.tbz2)
	    bzip2 -dc "$1" | tar tvvf -
	    ;;
	*.zip)
	    zipinfo -- "$1"
	    ;;
	*.rpm)
	    rpm -qpivl --changelog -- "$1"
	    ;;
	*.cpi|*.cpio)
	    cpio -itv < "$1"
	    ;;
	*.gif|*.jpeg|*.jpg|*.pcd|*.png|*.tga|*.tiff|*.tif)
	    if [ -x "`which identify`" ]; then
		identify "$1"
	    else
		echo "No identify available"
		echo "Install ImageMagick to browse images"
	    fi
	    ;;
	*.tzf)
	    bzcat "$1"
	    ;;
	*)
	    $cat -- "$1" ;;
    esac
}

if [ -d "$1" ] ; then
	/bin/ls -alF -- "$1"
else
	lesspipe "$1" 2> /dev/null
fi
