#!/bin/sh
#
# HR --Print a "horizontal rule" banner
#
# Remarks:
# This is a convenience for creating visible markers in terminal
# sessions, so they can be easily found in scroll-back.
#
# @todo: options for different colour banners
# @todo: options for timestamp format
# @todo: options for text alignment?
#
cols=${COLUMNS:-$(tput cols 2>/dev/null)}
cols=${cols:-80}

timestamp=$(date)
message="$timestamp: $* "
printf "\033[7m%${cols}s\033[m\n" "$message"
