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

	# if first arg looks like a flag, assume we want to run main.py
	if [ -s "main.py" ]; then
		if [ "${1:0:1}" == '-' ]; then
			exec python main.py "$@"
		fi

		if [ "$1" == "main.py" ]; then
			shift
			exec python main.py "$@"
		fi
	fi
	exec "$@"
}

if ! _is_sourced; then
	_main "$@"
fi
