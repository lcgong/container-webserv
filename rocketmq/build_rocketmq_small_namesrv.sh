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
container=$(buildah from "localhost/rocketmq-small:latest")
echo "buildah working container: $container"

buildah copy $container "${BASE_DIR}/entrypoint_namesrv.sh" "/usr/sbin/entrypoint.sh"
brun chmod +x "/usr/sbin/entrypoint.sh"

bconf --volume "/root/logs"
bconf --volume "/root/store"
bconf --port 9876
bconf --cmd 'namesrv'

bconf --author='Chenggong Lyu'
buildah commit $container "rocketmq-small-namesrv:latest"

