#!/usr/bin/sed -f
#
# TSV-TO-CSV.SED --Simplistic tab-separated to comma-separated values conversion.
#
# escape special characters...
s/,/::comma::/g
s/"/::quote::/g
#
# substitute tabs and force quotes...
s/	/","/g
s/^/"/
s/$/"/
s/NULL//g
s/,"",/,,/g
#
# undo special character escapes (and now '"' must be doubled)...
s/::comma::/,/g
s/::quote::/""/g
