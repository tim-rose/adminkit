#!/bin/sh
#
# MC-CMD --Run a single mailchimp command.
#
# Remarks:
# This is useful for manipulating the remote mailchimp data via shell scripts.
# Ouch! the mailchimp key is embedded in this script.
#
# See Also:
# http://apidocs.mailchimp.com/api/rtfm/
#
PATH=$PATH:/usr/libexec:/usr/local/libexec
. getopt.shl
. log.shl

tmpfile=${TMPDIR:-/tmp}/$0-$$
trap "rm -f $tmpfile" 0

#
# usage() --echo this script's usage message.
#
usage()
{
    #vcs_keyword 'db-dump.sh (unknown version)'
    cat <<EOF
mc-cmd: send a mailchimp command
EOF
    getopt_usage "mc-cmd <cmd> [options] [cmd-args...]" "$1"
}

case $1 in
    -*) ;;
    *) mc_cmd=$1; shift;;
esac

mc_api_key=${MAILCHIMP_KEY:-'88f7d4ea19e87d4af4ed0038238902d1-us1'}
mc_dc=$(echo $mc_api_key | sed -e 's/.*-//')
mc_url="http://$mc_dc.api.mailchimp.com/1.3/"

opts="k.key=$mc_api_key;c.command=$mc_cmd;t.type=json;u.url=$mc_url"
opts="$opts;$LOG_GETOPTS"

eval $(getopt_long_args -d "$opts" "$@" || usage "$opts" >&2)
log_getopts

if [ ! "$key" ]; then
    err 'no newrelic API key'
    usage
    exit 2;
fi

curl_opts=
for opt; do
    curl_opts="$curl_opts --data '$opt'"
done
eval "curl -s --data 'apikey=$mc_api_key' --data 'output=$type' $curl_opts $mc_url?method=$mc_cmd"
echo ""					# force a newline
