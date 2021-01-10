
## 1. 安装`podman`、`buildah`和`skepo`
目前`podman`只支持`Linux`平台。`Windows 10`用户可以使用`WSL 2`使用`Linux`。

### 1.1. `Ubuntu`安装podman

```sh
$ source /etc/os-release

$ sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"

$ wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | sudo apt-key add -

$ sudo apt-get update

$ sudo apt install podman buildah skepo
```

### 1.2 `k8s.gcr.io/pause`的安装
在使用podman的pod功能是需要`k8s.gcr.io/pause`创建Pod内可以彼此平等共享网络名称空间。
但是目前国内网络无法连接`k8s.gcr.io`，因此需要间接使用国内的镜像，然后再tag原来的命名。
```sh
podman pull registry.aliyuncs.com/google_containers/pause:3.2
podman tag registry.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2
podman rmi registry.aliyuncs.com/google_containers/pause:3.2
```



## 4 使用skopeo查看私有库镜像信息
```
skopeo login -u testuser myregistry:5000
````

```
$ skopeo inspect docker://myregistry:5000/qdygl-serv:21001 | jq
{
  "Name": "myregistry:5000/qdygl-serv",
  "Digest": "sha256:f32f757eac8681f8bbc5c0433b43d947bfc73cd2de8fb62cff2c98fe8200e756",
  "RepoTags": [
    "21001"
  ],
  "Created": "2021-01-08T13:25:46.413507658Z",
  "DockerVersion": "",
  "Labels": {
    "io.buildah.version": "1.18.0"
  },
  "Architecture": "amd64",
  "Os": "linux",
  "Layers": [
    "sha256:f6291d8887317896606687305f6661ecfd884bc4e4523d948c39af71d3cf3a5d",
    "sha256:9e0775ca9a2f3180f9cd3ca1532446a8d6dc58f4970ab9babd6168fc117ddee7",
    "sha256:247a9afb7564837564ec955789095de51dec696556c9707b3a816919b54190be",
    "sha256:c27b7e8d0660d99a445920f7be804bc766880b832a8d99f982385ea5458a4033",
    "sha256:5e7491d166b688963d1f6d8d8b876bbf2468eae82b62a7b86140ec6968bc0070"
  ],
  "Env": [
    "PATH=/work/env/py39/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "VIRTUAL_ENV=/work/env/py39"
  ]
}

```
