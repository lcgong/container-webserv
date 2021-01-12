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
container=$(buildah from "quay.io/lcgong/openjdk:8u275")
echo "buildah working container: $container"

buildah copy $container "${BASE_DIR}/contrib/rocketmq-console-ng.jar" "/root"
buildah copy $container "${BASE_DIR}/entrypoint_console.sh" "/usr/sbin/entrypoint.sh"
brun sh -c 'chmod +x /usr/sbin/entrypoint.sh'
bconf --entrypoint '["entrypoint.sh"]'

bconf --workingdir "/root"
bconf --stop-signal SIGTERM
bconf --cmd "console"

bconf --author='Chenggong Lyu'
buildah commit $container "rocketmq-console:latest"
