#!/bin/sh
#
# GETOPT.SH --Unit tests for the getopt module.
#
PATH=..:$PATH
. getopt.shl
. tap.shl

plan 27

#
# getopt_short() tests
#
ok_eq $(getopt_short 'a.alpha;b.beta;g.gamma') 'abg' \
    'getopt_short: flags only'

ok_eq $(getopt_short 'a.alpha;b.beta=;g.gamma') 'ab:g' \
    'getopt_short: option with value; but no default'

ok_eq $(getopt_short 'a.alpha;b.beta=value;g.gamma') 'ab:g' \
    'getopt_short: option with simple default value'

ok_eq $(getopt_short 'a.alpha;b.beta=value.txt;g.gamma') 'ab:g' \
    'getopt_short: default values can contain "."'

ok_eq $(getopt_short 'a.alpha;b.beta=value txt;g.gamma') 'ab:g' \
    'getopt_short: default values can contain " "'
#
# getopt_long() tests
#
ok_eq $(getopt_long 'a.alpha;b.beta;g.gamma') 'alpha,beta,gamma' \
    'getopt_long: flags only'

ok_eq $(getopt_long 'a.alpha;b.beta=;g.gamma') 'alpha,beta:,gamma' \
    'getopt_long: option with value; but no default'

ok_eq $(getopt_long 'a.alpha;b.beta=value;g.gamma') 'alpha,beta:,gamma' \
    'getopt_long: option with simple default value'

ok_eq $(getopt_long 'a.alpha;b.beta=value.txt;g.gamma') 'alpha,beta:,gamma' \
    'getopt_long: default values can contain "."'

ok_eq $(getopt_long 'a.alpha;b.beta=value txt;g.gamma') 'alpha,beta:,gamma' \
    'getopt_long: default values can contain " "'

ok_eq $(getopt_long 'a.alpha;b.be_ta=value txt;g.gamma') 'alpha,be-ta:,gamma' \
    'getopt_long: variable names have "_" mapped to "-"'

#
# getopt_defaults() tests.
#
ok_eq "$(getopt_defaults 'a.alpha;b.beta;g.gamma')" '' \
    'getopt_defaults: flags only'

ok_eq "$(getopt_defaults 'a.alpha;b.beta=;g.gamma')" 'beta="";' \
    'getopt_defaults: empty value'

ok_eq "$(getopt_defaults 'a.alpha;b.beta=value;g.gamma')" 'beta="value";' \
    'getopt_defaults: simple value'

ok_eq "$(getopt_defaults 'a.alpha;b.beta=value.txt;g.gamma')" \
    'beta="value.txt";' \
    'getopt_defaults: value containing "."'

ok_eq "$(getopt_defaults 'a.alpha;b.beta=value txt;g.gamma')" \
    'beta="value txt";' \
    'getopt_defaults: value containing " "'

#
# getopt_var() tests.
#
opts='a.alpha;b.beta=value txt;g.gamma'

ok_eq "$(getopt_var "$opts" a)" 'alpha' 'getopt_var: simple flag'
ok_eq "$(getopt_var "$opts" b)" 'beta=' 'getopt_var: option w/ value'
ok_eq "$(getopt_var "$opts" g)" 'gamma' 'getopt_var: flag after option'

#
# getopt_args() tests.
#
opts='a.alpha;b.beta=value;g.gamma'

OPTIND=1			# reset getopt state!
ok_grep "$(getopt_args "$opts" -x 2>/dev/null)" "exit 2;" \
    'getopt_args: invalid flag causes exit'

OPTIND=1
ok_eq "$(getopt_args "$opts")" 'OPTIND=1' 'getopt_args: empty arglist'

OPTIND=1
ok_eq "$(getopt_args "$opts" -a)" \
    "$(printf '%s\n' 'alpha=1;' 'OPTIND=2')" \
    'getopt_args: single flag specified'

OPTIND=1
ok_eq "$(getopt_args "$opts" -ag)" \
    "$(printf '%s\n' 'alpha=1;' 'gamma=1;' 'OPTIND=2')" \
    'getopt_args: two flags specified together'

OPTIND=1
ok_eq "$(getopt_args "$opts" -a -g)" \
    "$(printf '%s\n' 'alpha=1;' 'gamma=1;' 'OPTIND=3')" \
    'getopt_args: two flags specified separately'

OPTIND=1
result=$(printf '%s\n' 'alpha=1;' 'gamma=1;' 'beta="foobar";' 'OPTIND=3')
ok_eq "$(getopt_args "$opts" -agb foobar)" "$result" \
    'getopt_args: flags and values specified'

#
# getopt_args() "-d" tests
#
OPTIND=1
result=$(printf '%s\n' 'beta="value";' 'OPTIND=1')
ok_eq "$(getopt_args -d "$opts")" "$result" \
    'getopt_args: "-d" supplies default value'

OPTIND=1
result=$(printf '%s\n' 'beta="value";' 'beta="foobar";' 'OPTIND=3')
ok_eq "$(getopt_args -d "$opts" -b foobar)" "$result" \
    'getopt_args: "-d" command-line overrides defaults'
exit 0
