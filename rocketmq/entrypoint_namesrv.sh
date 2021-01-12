#!/usr/bin/env bash
set -Eeo pipefail

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] &&
		[ "${FUNCNAME[0]}" = '_is_sourced' ] &&
		[ "${FUNCNAME[1]}" = 'source' ]
}

_main() {

	if [ "$1" == "namesrv" ]; then
        shift
        exec java -server $JAVA_OPTS \
            -Djava.ext.dirs=/root/lib -cp /root/conf \
            org.apache.rocketmq.namesrv.NamesrvStartup "$@"
	fi

	exec "$@"
}

if ! _is_sourced; then
	_main "$@"
fi
