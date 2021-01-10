



![pod architecture](images/podman-pod-architecture.png)

每个**pod**都包含一个基础的“infra”容器，管理pod内各容器互连。
默认该容器来自k8s.gcr.io/pause镜像。


```
podman pod create
```

podman pod list