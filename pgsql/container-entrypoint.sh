#!/usr/bin/env bash
set -Eeo pipefail

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

_init_database() {
    echo $"Initializing database ..."
    if [ -z "$POSTGRES_PASSWORD" ]; then
        echo $"The enviroment POSTGRES_PASSWORD is required."
        echo $"POSTGRES_PASSWORD is the 'postgres' user's password."
        exit 1
    fi


	if [ -s "$PGDATA/PG_VERSION" ]; then
		echo $"ERROR: The database directory is not empty: ${PGDATA}"
        exit 1
	fi

	eval 'initdb --auth=scram-sha-256 --pwfile=<(echo $POSTGRES_PASSWORD)'

}

_check_pgdata_existing() {


    # Check for the PGDATA structure
    if [ -f "$PGDATA/PG_VERSION" ] && [ -d "$PGDATA/base" ]
    then
        # Check version of existing PGDATA
        if [ x`cat "$PGDATA/PG_VERSION"` = x"$PGVERSION" ]
        then
            : A-OK
        else
            echo $"WARNING: "
            echo $"    An old version of the database format was found."
            echo $"    You need to dump and reload before using PostgreSQL $PGVERSION."
            exit 1
        fi
    else
        # No existing PGDATA! Warn the user to initdb it.
        echo $"\"$PGDATA\" is missing or empty."
        echo $"Use \"container cmd initdb\" to initialize the database."
        exit 1
    fi
}



_main() {

    if [ ! "$1" = 'postgres' ]; then
        exec "$@"
        exit 0
    fi

    #########################################################################
    if [ -z "$PGDATA" ]; then
        echo $"ERROR: The environment PGDATA is required."
        echo $"       Set PGDATA to set the database directory path."
        exit 1
    fi


    if [ "$(id -u)" = '0' ]; then
    	# fix the volume user to postgres
        find "$PGDATA" \! -user postgres -exec chown postgres '{}' +

        # then restart script as postgres user
        exec gosu postgres "$BASH_SOURCE" "$@"
    fi

	if [ ! -s "$PGDATA/PG_VERSION" ]; then
        _init_database "$@"
	fi

    # Check version of existing PGDATA
    PGVERSION=$(pg_config --version | sed -r 's/^\w+\s+([0-9]+).*/\1/')
    if [ ! x`cat "$PGDATA/PG_VERSION"` = x"${PGVERSION}" ]; then
        echo $"WARNING: "
        echo $"    An old version of the database format was found."
        echo $"    You need to dump and reload before using PostgreSQL ${PGVERSION}."
        exit 2
    fi

    exec "$@"
}

if ! _is_sourced; then
	_main "$@"
fi