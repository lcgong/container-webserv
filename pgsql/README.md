

假定数据库存储在`/var/pgdata`目录下，第一次启动，如果没有初始化库，会自动初始化库。
初始化需要指定`postgres`用户密码，因此需要设定`POSTGRES_PASSWORD`环境变量，初始化之后无需包含该变量。
```sh 
podman run -it \
   -e POSTGRES_PASSWORD=postgres \
   -v /var/pgdata:/pgdata \
   -p 5432:5432 quay.io/lcgong/pgsql13:21001
```

以后台方式运行
```sh 
podman run -dt \
   -e POSTGRES_PASSWORD=postgres \
   -v /var/pgdata:/pgdata \
   -p 5432:5432 quay.io/lcgong/pgsql13:21001
```

* `--name`指定容器名为`pgserv`

查看日志
   ```
   podman logs pgserv
   ```
或者使用参数`-f`持续追看数据库日志
   ```
   podman logs -f pgserv
   ```

