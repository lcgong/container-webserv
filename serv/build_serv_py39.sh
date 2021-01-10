#!/usr/bin/env bash
set -o errexit
function brun() {
    buildah run $container -- "$@"
}

function bconf() {
    buildah config "$@" $container
}

BASE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

## 开始从基础镜像构建
container=$(buildah from "docker.io/library/ubuntu:20.04")
echo "buildah working container: $container"

brun rm -rf /etc/localtime
brun ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

brun sh -c "cat - > /etc/apt/sources.list" <<EOF
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
brun apt -y update
brun apt -y upgrade
brun apt -y --no-install-recommends \
    install gnupg locales curl build-essential binutils binfmt-support

brun locale-gen zh_CN.UTF-8
brun update-locale LANG=zh_CN.UTF-8 LC_MESSAGES=POSIX

brun apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv F23C5A6CF475977595C89F51BA6932366A755776
# 国内launchpad连接不稳定，用中科大(ustc)逆向代理替代launchpad镜像
# 中科大逆向代理证书采用自签证书，需要禁用apt根除证书检查
# brun sh -c 'echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu focal main" >  /etc/apt/sources.list.d/python.list'
brun sh -c 'echo "deb https://launchpad.proxy.ustclug.org/deadsnakes/ppa/ubuntu focal main" >  /etc/apt/sources.list.d/python.list'
brun sh -c 'echo "Acquire::https::launchpad.proxy.ustclug.org { Verify-Peer "false"; Verify-Host "false"; }" > /etc/apt/apt.conf.d/ustclug_launchpad'

brun apt -y update
brun apt -y --no-install-recommends \
    install python3.9 python3.9-venv python3.9-dev
brun sh -c "rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/backups/*"

brun python3.9 -m venv "/root/env/py39"-
bconf --env VIRTUAL_ENV="/root/env/py39"
bconf --env PATH="/root/env/py39/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

brun mkdir -p "/root/serv"
bconf --workingdir "/root/serv"
bconf --volume "/root/serv"

buildah copy $container "${BASE_DIR}/entrypoint.sh" "/usr/sbin"
brun chmod +x "/usr/sbin/entrypoint.sh"
bconf --entrypoint '["entrypoint.sh"]'

bconf --port 8000
bconf --stop-signal SIGINT
bconf --cmd 'main.py'

bconf --author='Chenggong Lyu'
buildah commit $container "serv-py39:latest"

