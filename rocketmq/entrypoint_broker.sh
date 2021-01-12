#!/usr/bin/env bash
set -Eeo pipefail

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] &&
		[ "${FUNCNAME[0]}" = '_is_sourced' ] &&
		[ "${FUNCNAME[1]}" = 'source' ]
}

_generate_broker_config() {
	cat - > /root/conf/broker.conf << EOF
brokerClusterName = DefaultCluster
brokerName = broker-a
brokerId = 0
deleteWhen = 04
fileReservedTime = 48
brokerRole = ASYNC_MASTER
# flushDiskType = ASYNC_FLUSH
flushDiskType = SYNC_FLUSH
EOF
	if [ -z "${HOST_IP}" ]; then
		HOST_IP="localhost"
	fi

	echo $"namesrvAddr=${HOST_IP}:9876" >> /root/conf/broker.conf
	echo $"brokerIP1=${HOST_IP}" >> /root/conf/broker.conf
}

_main() {

	if [ "$1" == "broker" ]; then
        shift
		_generate_broker_config
        exec java -server $JAVA_OPTS \
            -Djava.ext.dirs=/root/lib -cp /root/conf \
            org.apache.rocketmq.broker.BrokerStartup -c /root/conf/broker.conf
	fi

	exec "$@"
}

if ! _is_sourced; then
	_main "$@"
fi
