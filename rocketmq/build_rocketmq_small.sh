#!/usr/bin/env bash
function brun() {
    buildah run $container -- "$@"
}

function bconf() {
    buildah config "$@" $container
}

BASE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

mkdir -p "${BASE_DIR}/contrib"
ROCKETMQ_PKG_NAME="rocketmq-all-4.8.0-bin-release"
ROCKETMQ_PKG="${BASE_DIR}/contrib/${ROCKETMQ_PKG_NAME}.zip"
echo $"prepareing $ROCKETMQ_PKG"
if [ ! -s "${ROCKETMQ_PKG}" ]; then
    wget -O "${ROCKETMQ_PKG}" "https://mirror.dsrg.utoronto.ca/apache/rocketmq/4.8.0/rocketmq-all-4.8.0-bin-release.zip"
fi

if [ -s "$ROCKETMQ_PKG" ]; then
    unzip -tqq "${ROCKETMQ_PKG}"
    if [ $? -ne 0 ]; then
        echo $"ERROR: invalid package ${ROCKETMQ_PKG}"
        exit 1
    fi
fi

set -o errexit

# 开始从基础镜像构建
container=$(buildah from "quay.io/lcgong/openjdk:8u275")
echo "buildah working container: $container"

brun apt -y update
brun apt -y --no-install-recommends install unzip

ROCKETMQ_ZIP="rocketmq-all-4.8.0-bin-release"
buildah copy $container "$BASE_DIR/contrib/$ROCKETMQ_ZIP.zip" /tmp
brun sh -c "cd /tmp; unzip -q $ROCKETMQ_ZIP.zip; mv $ROCKETMQ_ZIP/* /root/; rm -rf $ROCKETMQ_ZIP*"
# brun sh -c $'sed -ri \'s@^sh \$\{ROCKETMQ_HOME\}@bash ${ROCKETMQ_HOME}@g\' /root/bin/mqnamesrv'
bconf --workingdir "/root"
bconf --env ROCKETMQ_HOME="/root"
bconf --stop-signal SIGTERM

buildah copy $container "${BASE_DIR}/entrypoint.sh" "/usr/sbin"
brun chmod +x "/usr/sbin/entrypoint.sh"
bconf --entrypoint '["entrypoint.sh"]'

echo 111
brun sh -c 'apt -y remove unzip'
echo 122
brun sh -c 'apt -y autoremove; apt -y clean --dry-run'
brun sh -c 'rm -rf /var/lib/apt/lists/*'

bconf --author='Chenggong Lyu'
buildah commit $container "rocketmq-small:latest"

