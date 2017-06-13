#!/usr/bin/sed -f
#
# WWW-TO-TSV.SED --Simplistic web log converter
#
# IP address
s/ \+/	/
# RFC1413 ID (or "-")
s/ \+/	/
# authenticated user ID (or "-")
s/ \+/	/
# timestamp
s/ \+\[/	/
# merge timezone
s/ //
# HTTP method
s/\] "/	/
# request URL
s/" /	/
# HTTP status
# TODO: other www log file fields...
