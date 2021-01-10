#!/usr/bin/env bash
set -o errexit

if [ -z "$1" ]
  then
    echo "No VESION tag supplied: such as $0 21017"
    exit 1
fi
TAG=$1

BASE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))
# BUILD_DIR=$(realpath ${BASE_DIR}/build)
# mkdir -p "${BUILD_DIR}"

## 开始从基础镜像构建
BASE_IMAGE="docker.io/lcgong/ubuntu-base:21001"
container=$(buildah from "${BASE_IMAGE}")
echo "buildah working container: $container"
echo "base image: ${BASE_IMAGE}"

function brun() {
  buildah run $container -- "$@"
}

## 开始构建
brun apt install nginx -y

buildah copy $container "${BASE_DIR}/index.html" "/var/www/html"
buildah copy $container "${BASE_DIR}/nginx_default.conf" "etc/nginx/sites-enabled/default"


buildah config --port 8080 $container
buildah config --entrypoint "/usr/sbin/nginx -g \"daemon off;\"" $container

buildah commit --rm $container "nginx-webapp:${TAG}"
