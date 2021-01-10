#!/usr/bin/env bash
set -o errexit
function brun() {
    buildah run $container -- "$@"
}

function bconf() {
    buildah config "$@" $container
}

BASE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

PG_MAJOR=13
PGDATA=/pgdata

## 开始从基础镜像构建
container=$(buildah from "docker.io/library/ubuntu:20.04")
echo "buildah working container: $container"

brun rm -rf /etc/localtime
brun ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

brun sh -c "cat - > /etc/apt/sources.list" << EOF
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
brun apt update

brun apt install -y --no-install-recommends gnupg2 locales gosu 

brun locale-gen zh_CN.UTF-8
brun update-locale LANG=zh_CN.UTF-8 LC_MESSAGES=POSIX

brun mkdir -p /var/lib/postgresql
brun groupadd -r postgres --gid=999
brun useradd -r -g postgres \
    --uid=999 \
    --home-dir=/var/lib/postgresql \
    --shell=/bin/bash postgres
brun chown -R postgres:postgres /var/lib/postgresql

# PGDG keyring
brun apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
# cat "${BASE_DIR}/pgdg-key-ACCC4CF8.asc" | brun apt-key add -
brun sh -c "cat - > /etc/apt/sources.list.d/pgdg.list"  << EOF
deb http://mirrors.aliyun.com/postgresql/repos/apt focal-pgdg main
EOF

brun apt update
brun apt -y --no-install-recommends install postgresql-${PG_MAJOR}
brun apt -y upgrade
brun apt -y autoremove
brun sh -c "rm -rf /etc/postgresql /etc/postgresql-common /var/lib/postgresql/*"
brun sh -c "rm -rf /etc/systemd /var/lib/apt/lists/*"

buildah copy $container "${BASE_DIR}/container-entrypoint.sh" "/usr/sbin/"
brun chmod +x "/usr/sbin/container-entrypoint.sh"

echo "PATH=\"/usr/sbin:/usr/bin:/usr/lib/postgresql/${PG_MAJOR}/bin\"" \
  | brun sh -c "cat - > /etc/environment" 

bconf --env PATH="/usr/sbin:/usr/bin:/usr/lib/postgresql/${PG_MAJOR}/bin"
bconf --env PGDATA="${PGDATA}"

brun mkdir -p "${PGDATA}"
brun chown -R postgres:postgres "${PGDATA}"
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
brun chmod 777 "${PGDATA}"
bconf --volume "${PGDATA}"

bconf --port 5432

bconf --stop-signal SIGINT
bconf --entrypoint '["container-entrypoint.sh"]'
bconf --cmd "postgres"

brun apt -y clean --dry-run

buildah commit --squash $container "pgsql13:latest"

## REFERRENCE:
## * https://github.com/docker-library/postgres/blob/master/13/Dockerfile
## * https://github.com/docker-library/postgres/blob/master/13/docker-entrypoint.sh
