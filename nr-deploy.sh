#!/bin/sh
#
# NR-DEPLOY --Notify newrelic that we've done a deployment.
#
# Remarks:
# The newrelic config is stored in /etc/newrelic/newrelic.cfg, so it usually
# doesn't need to be specified on the command line.
#
# See Also:
# http://newrelic.github.com/newrelic_api
#
PATH=$PATH:/usr/libexec:/usr/local/libexec
. getopt.shl
. log.shl
newrelic_url='https://rpm.newrelic.com/deployments.xml'
tmpfile=${TMPDIR:-/tmp}/$(basename $0)-$$

trap "rm -f $tmpfile" 0

#
# load newrelic defaults, if we can...
#
if [ -f /etc/newrelic/newrelic.cfg ]; then
    . /etc/newrelic/newrelic.cfg
fi

#
# usage() --echo this script's usage message.
#
usage()
{
    cat <<EOF
nr-deploy: send a newrelic deployment notification to newrelic
EOF
    getopt_usage "nr-deploy [options] [databases...]" "$1"
}

USER=${USER:-$LOGNAME}
opts="k.key=$license_key;n.name=;i.id=;r.revision=;d.description=;u.user=$USER"
opts="$opts;$LOG_GETOPTS"
eval $(getopt_long_args -d "$opts" "$@" || usage "$opts" >&2)
log_getopts

if [ ! "$key" ]; then
    err 'no newrelic API key'
    usage
    exit 2;
fi

#
# Get the application specification, which can be supplied as either
# a name or an ID.
#
app_spec=
if [ "$name" ]; then
    app_spec=app_name
elif [ "$id" ]; then
    app_spec=application_id
    name=$id
else
    err 'no newrelic app name or ID specified'
    usage
    exit 2;
fi
curl_opts="--data-urlencode 'deployment[$app_spec]=$name'"

#
# Expand user from the password entry's gecos if possible.
# (cleanup trailing "," [damn you to hell adduser!])
#
if [ "$user" ]; then
    pw_user=$(grep tim /etc/passwd | cut -d: -f5 | sed -e 's/,*$//')
    if [ "$pw_user" ]; then
	user=$pw_user
    fi
    curl_opts="$curl_opts --data-urlencode 'deployment[user]=$user'"
fi


if [ "$revision" ]; then
    curl_opts="$curl_opts --data-urlencode 'deployment[revision]=$revision'"
fi

if [ "$description" ]; then
    curl_opts="$curl_opts --data-urlencode 'deployment[description]=$description'"
fi

#
# let's go...
#
debug 'curl_opts: %s' "$curl_opts"
eval curl -f --header 'x-license-key:$key' $curl_opts $newrelic_url >$tmpfile
if [ $? -ne 0 ]; then
    err "request failed"
    exit 1
fi

#
# TODO: post-process $tmpfile to provide user feedback about success...
#
