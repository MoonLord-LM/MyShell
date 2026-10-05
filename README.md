# MyShell
[![self-check](https://github.com/MoonLord-LM/MyShell/actions/workflows/self-check.yml/badge.svg)](https://github.com/MoonLord-LM/MyShell/actions/workflows/self-check.yml)

Common Linux Shell scripts and function library  
Provides some practical utility functions on Ubuntu / Debian servers, and one-click installation, configuration and tuning scripts for common software  

常用 Linux Shell 脚本和函数库  
提供在 Ubuntu / Debian 服务器上的一些实用的功能函数，以及一些常用软件的一键安装配置调优脚本  

## [使用说明]

### 功能函数

需要先执行 source 命令，加载 My.sh 之后，才可以执行函数  

```bash
source <( wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
```

| 分类 | 函数 | 说明 |
| --- | --- | --- |
| 设置 | `prepare_common_command`         | 安装常用命令（curl、openssl 等） |
| 设置 | `reset_root_password`            | 重设 root 密码为 Base64 编码的 256 bit 随机数，并显示新密码 |
| 设置 | `set_timezone_china`             | 设置系统时区为中国时区（Asia/Shanghai GMT+08:00） |
| 设置 | `set_tcp_congestion_control_bbr` | 设置 TCP 拥塞控制算法为 BBR |
| 设置 | `set_tcp_network_buffer`         | 设置 TCP 收发缓冲区上限为 16MB |
| 设置 | `set_tcp_fastopen`               | 设置 TCP Fast Open 为 3（客户端+服务端） |
| 设置 | `set_memory_swap_to_4GB`         | 设置虚拟内存，保证物理内存 + 虚拟内存总量在 4GB 以上 |
| 设置 | `update_software`                | 更新软件 |
| 设置 | `update_software_aggressive`     | 更新软件，更激进 |
| 设置 | `update_system`                  | 系统版本升级（Debian 升级到 13，Ubuntu 升级到 26.04） |
| 查看 | `get_system_name`                | 获取系统名称 |
| 查看 | `get_system_version_codename`    | 获取系统版本代号 |
| 查看 | `get_system_ip`                  | 获取系统的 IP |
| 查看 | `show_software_list`             | 展示所有已安装的程序和版本 |
| 查看 | `show_tcp_listening`             | 展示正在监听的 TCP 端口 |
| 查看 | `show_disk_usage`                | 展示物理磁盘使用 |

### 部署脚本

脚本可重复执行，已安装时直接退出  
优先使用 export 的环境参数，无参数时，使用高强度的随机数，并在日志中显示  

#### 安装 MySQL（监听端口 13306，开启 SSL）

```bash
# export MYSQL_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/mysql.sh' | bash
```

#### 安装 Redis（监听端口 16379，开启 SSL）

```bash
# export REDIS_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/redis.sh' | bash
```

#### 安装 Nginx（监听端口 80、443，开启 Http 强制跳转 Https）

```bash
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash
```

#### 安装 PHP

```bash
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/php.sh' | bash
```

#### 安装 Cockpit（面板端口 19190，开启 Https）

```bash
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/cockpit.sh' | bash
```

#### 安装 Shadowsocks（监听端口 10000，加密算法 2022-blake3-aes-256-gcm）

```bash
# export SS_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks.sh' | bash
```

#### 安装 V2Ray（监听端口 10010）

```bash
# export V2RAY_CLIENT_ID="<预设客户端ID>"
# export V2RAY_WS_PATH="<预设路径>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash
```

#### 安装 Docker

```bash
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash
```

#### 安装 Frp 服务端（依赖 Docker 部署，监听端口 17000，Https 服务端口 17443，面板端口 17500，开启 SSL/Https）

```bash
# export FRP_TOKEN="<预设连接Token>"
# export FRP_DASHBOARD_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/frp.sh' | bash
```

#### 安装 Grafana（依赖 Docker 部署，面板端口 13000，开启 Https）

```bash
# export GRAFANA_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/grafana.sh' | bash
```

#### 安装 Portainer CE（依赖 Docker 部署，面板端口 19443，开启 Https）

```bash
# export PORTAINER_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/portainer.sh' | bash
```

#### 安装 Prometheus（依赖 Docker 部署，面板端口 19090，开启 Https）

```bash
# export MYSQL_PASSWORD="<预设密码>"
# export REDIS_PASSWORD="<预设密码>"
# export PROMETHEUS_PASSWORD="<预设密码>"
wget -O- --timeout=10 --no-cache \
'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/prometheus.sh' | bash
```

## [目录结构]

```
MyShell/
├── bash/
│   ├── My.sh                 # 核心函数库
│   ├── install/
│   │   ├── cockpit.sh        # Cockpit 安装
│   │   ├── docker.sh         # Docker 安装
│   │   ├── mysql.sh          # MySQL 安装
│   │   ├── nginx.sh          # Nginx 安装
│   │   ├── php.sh            # PHP 安装
│   │   ├── redis.sh          # Redis 安装
│   │   ├── shadowsocks.sh    # Shadowsocks 安装
│   │   └── v2ray.sh          # V2Ray 安装
│   └── docker/
│       ├── frp.sh            # Frp 服务端安装
│       ├── grafana.sh        # Grafana 安装
│       ├── portainer.sh      # Portainer CE 安装
│       └── prometheus.sh     # Prometheus 安装
├── resource/
│   ├── grafana/dashboard/    # Grafana 仪表盘配置示例
│   └── nginx/config/         # Nginx 配置示例
├── LLM.md                    # 提示信息
├── README.md                 # 工程说明
└── self-check.sh             # 自检脚本
```
