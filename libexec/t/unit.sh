#!/bin/sh
#
# GETOPT.SH --Unit tests for the getopt module.
#
PATH=..:$PATH
. core.shl
require unit.shl tap.shl

plan 12

#
# duration parsing tests
#
ok_eq $(opt_duration 0) 0 'opt_duration: simple zero'
ok_eq $(opt_duration 0s) 0 'opt_duration: zero seconds'
ok_eq $(opt_duration 10s) 10 'opt_duration: nonzero seconds'
ok_eq $(opt_duration 5M) $(( 5*60 )) 'opt_duration: minutes'
ok_eq $(opt_duration 5h) $(( 5*60*60 )) 'opt_duration: hours (h)'
ok_eq $(opt_duration 5H) $(( 5*60*60 )) 'opt_duration: hours (H)'
ok_eq $(opt_duration 5d) $(( 5*24*60*60 )) 'opt_duration: days (d)'
ok_eq $(opt_duration 5D) $(( 5*24*60*60 )) 'opt_duration: days (D)'
ok_eq $(opt_duration 5w) $(( 5*7*24*60*60 )) 'opt_duration: weeks (w)'
ok_eq $(opt_duration 5m) $(( 5*30*24*60*60 )) 'opt_duration: months (m)'
ok_eq $(opt_duration 5y) $(( 5*365*24*60*60 )) 'opt_duration: years (y)'

todo 'support mixed duration units'
ok $(quietly opt_duration 5y5m5w5d5h5M5s; echo $?) 'opt_duration: mixed'
todo
exit 0
