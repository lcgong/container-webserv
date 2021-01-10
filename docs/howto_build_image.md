
## 在容器内进行查看

1. 使用`podman ps`查看运行容器的ID
     ```sh
     # podman ps
     CONTAINER ID   IMAGE           COMMAND           CREATED       STATUS        PORTS   NAMES
     74b1da000a11   rsyslog:latest "/usr/rsyslog.sh   6 minutes ago Up 6 minutes          rsyslog
     ```
     
1. 使用`podman exec`打开指定容器ID的bash shell以访问正在运行的容器
     ```sh
     # podman exec -it 74b1da000a11 /bin/bash
     [root@74b1da000a11 /]# yum install procps-ng
     [root@74b1da000a11 /]# ps -ef
     UID        PID  PPID  C STIME TTY          TIME CMD
     root         1     0  0 15:30 ?        00:00:00 /usr/sbin/rsyslogd -n
     root         8     0  6 16:01 pts/0    00:00:00 /bin/bash
     root        21     8  0 16:01 pts/0    00:00:00 ps -ef
     ```



```
buildah unshare -- sh -c "buildah mount 4b258341e17c"

buildah unshare -- sh -c "buildah unmount 4b258341e17c"
```

```
#!/usr/bin/env bash

set -o errexit

# Create a container
container=$(buildah from fedora:28)
mountpoint=$(buildah mount $container)

curl -sSL http://ftpmirror.gnu.org/hello/hello-2.10.tar.gz \
     -o /tmp/hello-2.10.tar.gz
tar xvzf src/hello-2.10.tar.gz -C ${mountpoint}/opt

pushd ${mountpoint}/opt/hello-2.10
./configure
make
make install DESTDIR=${mountpoint}
popd

chroot $mountpoint bash -c "/usr/local/bin/hello -v"

buildah config --entrypoint "/usr/local/bin/hello" $container
buildah commit --format docker $container hello
buildah unmount $container
```

The chroot command here is used to change root into the mountpoint itself and test that "hello" is working, similar to the buildah run command used in the previous example.
