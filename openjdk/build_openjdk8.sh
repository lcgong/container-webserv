#!/usr/bin/env bash
set -o errexit
function brun() {
    buildah run $container -- "$@"
}

function bconf() {
    buildah config "$@" $container
}

BASE_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))


mkdir -p contrib
JDK_PKG="$BASE_DIR/contrib/OpenJDK8U-jdk_x64_linux_8u275b01.tar.gz"
if [ ! -s "$JDK_PKG" ]; then
    wget -O "$JDK_PKG" 'https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_x64_linux_8u275b01.tar.gz'
fi

# 开始从基础镜像构建
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
brun sh -c 'apt -y update; apt -y upgrade'
brun apt -y --no-install-recommends install locales ca-certificates p11-kit

brun sh -c 'locale-gen zh_CN.UTF-8; update-locale LANG=zh_CN.UTF-8 LC_MESSAGES=POSIX'

bconf --env JAVA_HOME="/opt/openjdk8"
bconf --env PATH="/opt/openjdk8/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

brun sh -c 'mkdir -p "${JAVA_HOME}";'


buildah copy $container "$JDK_PKG" "/opt/openjdk8.tgz"

brun sh -c 'cd /opt; tar xfz openjdk8.tgz --strip-components 1 --directory "${JAVA_HOME}"; rm openjdk8.tgz'
brun sh -c 'cd "${JAVA_HOME}"; rm -rf src.zip demo sample man'

brun sh -c 'cat - > /etc/ca-certificates/update.d/container-openjdk' << EOF
#!/usr/bin/env bash
set -Eeuo pipefail

if ! [ -d "\$JAVA_HOME" ]; then
    echo >&2 "error: missing JAVA_HOME environment variable"
    exit 1 
fi

cacertsFile=""
for f in "\$JAVA_HOME/lib/security/cacerts" "\$JAVA_HOME/jre/lib/security/cacerts"; do 
    if [ -e "\$f" ]; then 
        cacertsFile="\$f"; break; 
    fi; 
done

if [ -z "\$cacertsFile" ] || ! [ -f "\$cacertsFile" ]; then
    echo >&2 "error: failed to find cacerts file in \$JAVA_HOME"
    exit 1
fi

trust extract --overwrite --format=java-cacerts \\
    --filter=ca-anchors \\
    --purpose=server-auth "\$cacertsFile"
EOF
brun sh -c "chmod +x /etc/ca-certificates/update.d/container-openjdk"
brun sh -c "/etc/ca-certificates/update.d/container-openjdk"

brun sh -c $'find "$JAVA_HOME/lib" -name \'*.so\' -exec dirname \'{}\' \';\' | sort -u > /etc/ld.so.conf.d/container-openjdk.conf'
brun sh -c 'java -version'

brun sh -c "apt -y remove locales ca-certificates p11-kit"
brun sh -c 'apt -y autoremove; apt -y clean --dry-run'
brun sh -c 'rm -rf /var/lib/apt/lists/*'
bconf --workingdir "/root"

bconf --author='Chenggong Lyu'
buildah commit --squash $container "openjdk:8u275"
