# nginx-rtmp
开箱即用的 Nginx-RTMP 服务器，内置推送源管理界面。

提供 `x86_64`、`arm64` 平台镜像，PC、服务器、树莓派都能用。

基于 `alpine:3.20` + `nginx 1.26` 构建，集成最新版 `nginx-rtmp-module`，同时内置 Flask Web 控制台，方便增删推送源并自动重载配置。

# 版本记录
版本号默认跟随 Nginx Stable 分支的版本号，从 1.26.2 起提供最新版镜像。
- `1.26.2`, `latest`

# Github仓库地址
镜像 Github 仓库：[https://github.com/jinuljt/nginx-rtmp](https://github.com/jinuljt/nginx-rtmp)

# 本镜像的用途
`Nginx` 是一个高性能的 HTTP 服务器，本镜像集成了 `nginx-rtmp-module` 插件，可配置为直播推流服务器。全新的 Web 控制台支持在线管理推送源，无需手动修改 `nginx.conf`。

本镜像适用于 `PS4`、`PS5` 的直播推流，也可以用作一般的串流服务器。

# 使用方法
## 开启服务
- 作为直播推流服务器使用，可通过以下命令启用服务：

```bash
docker run -d --name nginx-rtmp \
  -p 1935:1935 \
  -p 8080:8080 \
  -p 5000:5000 \
  jinuljt/nginx-rtmp
```

浏览器访问`http://localhost:8080`，显示如下界面：说明服务开启成功
![stat界面](https://i.loli.net/2021/08/03/Z3WGqAxMyXiJ4Rc.png)  
`如果是在路由器、nas或者树莓派上运行，请自行把localhost改成宿主机IP地址`
- 如果不需要 Web 控制台，可以不映射 5000；若也不需要状态面板，可以不映射 8080：

```bash
docker run -d --name nginx-rtmp -p 1935:1935 jinuljt/nginx-rtmp
```

## 管理推送源

访问 `http://localhost:5000/` 打开 Web 控制台，可直接新增或删除推送地址，保存后容器会自动执行 `nginx -s reload`。

- 新增示例：`rtmp://live-push.example.com/live/stream_key`
- 删除推送时，仅需在列表中选择对应地址。

所有推送源会写入 `/etc/nginx/conf.d/rtmp_pushes.conf`，并同步保存到 `/var/lib/nginx-manager/push_sources.json`。

## PS5推流
目前PS5直播功能只能支持Twitch和油罐，因此大体思路是通过劫持Twitch推流到`nginx-rtmp`上以便达成目的
- 添加DNSMasq列表，把Twitch直播地址劫持为你的docker主机地址
- 保存应用路由器设置
- 打开PS5，按分享键，选择从Twitch直播
- 如果成功劫持了推流且模块工作正常，接下来会在网页中显示一段ID

`live_***************`
- 把这段ID复制下来粘贴到以下这个链接中替换live_******的部分注意这个链接的localhost也要替换为你宿主机的IP

`rtmp://localhost:1935/app/live_******`
- 使用OBS加载然后直播就完事了

# 高级设置
如果需要完全自定义配置，仍可挂载外部 `nginx.conf` 文件覆盖默认配置：

```bash
docker run -d --name nginx-rtmp \
  -p 1935:1935 -p 8080:8080 -p 5000:5000 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf \
  jinuljt/nginx-rtmp
```

Web 控制台生成的推送列表同样位于 `/etc/nginx/conf.d/rtmp_pushes.conf`，可以在自定义配置中用 `include` 引入，实现自定义与可视化管理混合使用。
