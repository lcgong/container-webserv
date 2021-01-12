#!/usr/bin/env bash
set -o errexit
function brun() {
    buildah run $container -- "$@"
}

function bconf() {
    buildah config "$@" $container
}

BASE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

# 开始从基础镜像构建
container=$(buildah from "rocketmq-small:latest")
echo "buildah working container: $container"

buildah copy $container "${BASE_DIR}/entrypoint_broker.sh" "/usr/sbin/entrypoint.sh"
brun chmod +x "/usr/sbin/entrypoint.sh"

bconf --port 10911
bconf --port 10909
bconf --port 10912

bconf --cmd "broker"

bconf --volume "/root/logs"
bconf --volume "/root/store"

buildah commit $container "rocketmq-small-broker:latest"

