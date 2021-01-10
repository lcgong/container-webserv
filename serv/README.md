

## 1. 镜像构建

在本地运行构建镜像
```sh
./build_serv_py39.sh
```

## 2. 标记版本标签
```
podman tag localhost/serv-py39:latest quay.io/lcgong/serv-py39:latest
podman tag quay.io/lcgong/serv-py39:latest quay.io/lcgong/serv-py39:21001
```

## 3. 登录镜像
```
podman login quay.io
podman push quay.io/lcgong/serv-py39:21001
podman push quay.io/lcgong/serv-py39:21001
``

临时启动容器查看
```sh
$ podman run -it -v /tmp:/work/serv -p 3801:8000 quay.io/lcgong/serv-py39:21001 bash
root@550ef0b1e1ce:/work/serv# 
root@550ef0b1e1ce:/work/serv# 
root@550ef0b1e1ce:/work/serv# 
```
