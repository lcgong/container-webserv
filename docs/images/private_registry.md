
## 1 私有Registry的搭建

安装[docker registry](https://github.com/docker/distribution)（[镜像](https://hub.docker.com/_/registry)）实现私有Registry镜像库

[](https://hub.docker.com/_/registry)
### 1.1 下载安装 **docker registry**
```
podman pull docker.io/library/registry:2
```

假定私有库存放在`/var/registry`目录下，镜像和用户登录数据分别存在该目录下的`data`和`auth`两个子目录。
```
$ sudo mkdir -p /var/registry
```
修改`/var/registry`目录所属用户和组，使得具有访问权限


```
$ cd /var/registry
$ mkdir data auth
```

### 2.2 创建用户

在docker registry的2.7版本后，htpasswd不再包含包里
```
sudo apt install apache2-utils
```

```
htpasswd -Bbn usertom userpass >> /var/registry/auth/htpasswd
```

### 2.3 独立容器运行服务

``` sh
podman run -dt --name registry \
  --restart=always \
  -p 5000:5000
  -v /var/registry/auth:/auth \
  -v /var/registry/data:/var/lib/registry \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM=RegistryRealm \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2
```

### 2.4 停止服务

停止服务，并删除容器和挂接点
```
podman container stop registry && podman rm -v registry
```


## 2 访问私有库


### 1 配置私有库
在`/etc/hosts`添加私有容器镜像库的主机名和IP地址，如`myregistry`。

在`/etc/containers/registrys.conf`文件内添加下面信息
```ini
unqualified-search-registries = ["myregistry:5000", "docker.io"]

[[registry]]
prefix = "myregistry"
location = "myregistry"
insecure = true
```

### 2 登录私有库
```
podman login myregistry:5000
```

### 3.3 向私有库推镜像

```
podman tag localhost/serv:latest myregistry:5000/serv:21001

podman push myregistry:5000/serv:21001
```

### 3.4 从私有库下载镜像
```
podman pull myregistry:5000/serv:21001
```

### 3.5 搜索镜像

```sh
$ podman search serv
INDEX            NAME                        DESCRIPTION  STARS   OFFICIAL  AUTOMATED
myregistry:5000  myregistry:5000/serv               0    
```
