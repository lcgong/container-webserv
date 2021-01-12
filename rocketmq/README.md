
## 部署运行

假设将RocketMQ的数据存放在`/w/rocketmq`。在该目录下创建`store`和`logs`两个子目录
```console
$ mkdir -p /w/rocketmq/logs /w/rocketmq/store
```

第一次安装运行，直接下载pod文件`mymq.yml`部署运行。
```console
$ podman play kube mymq.yml 

Pod:
afe303df13f4542fbdaac4e7a0ef2023f4fbe6334f722c0556dc4bc3195b9050
Containers:
fad67ab98cf391d9d743ca69533431592530b70f425529c3493b5675f871a637
67f2a5c9ae77d72146d50975b72fa89a6d39a5174ff2b0e7f6dfb0077d9f5f12
59caa736cf31e360cc0d2ad55226324aaf5a958586f35889afc8ed3d08a28f61

```

主机地址假定为`192.168.31.13`。注意，需要打开该文件将文件内HOST_IP修改为所在主机的地址，如下面片段
```yaml
....
    - name: ROCKETMQ_HOME
      value: /root
    - name: HOST_IP
      value: 192.168.31.13
    - name: HOSTNAME
      value: mymq
....
```


```console
$ podman ps --format "{{.ID}}\t {{.Names}} \t {{.Status}}"
....
59caa736cf31   mymq-namesrv          Up 5 minutes ago
1d2cd367e4a2   afe303df13f4-infra    Up 5 minutes ago
67f2a5c9ae77   mymq-console          Up 5 minutes ago
fad67ab98cf3   mymq-broker           Up 5 minutes ago
....
```



## 重新搭建rocketmq pod

```console
$ podman pod create --name mymq -p 9876:9876 -p 10911:10911 -p 10909:10909 -p 9888:8080

$ podman run -dt --pod mymq --name namesrv -v /w/rocketmq/logs:/root/logs -v /w/rocketmq/store:/root/store quay.io/lcgong/rocketmq-small-namesrv:21001

$ podman run -dt --pod mymq --name broker -e HOST_IP=192.168.31.13 -v /w/rocketmq/logs:/root/logs -v /w/rocketmq/store:/root/store quay.io/lcgong/rocketmq-small-broker:21001

$ podman run -dt --pod mymq --name console -e NAMESRV_ADDR=localhost:9876 quay.io/lcgong/rocketmq-console:2.0.0
```

产生pod的yml文件
```
$ podman generate kube mymq -f mymq.yml

```

