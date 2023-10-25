# MyShell

A function library for the Linux Shell.  
Linux Shell 常用脚本和函数库.  

## [测试系统]

Ubuntu 22.04 / Debian 11  

## [使用说明]

    # 加载函数
    source <( wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )

    # 常用函数
    set_timezone_china
    set_tcp_congestion_control_bbr
    set_iptables_accept_all
    update_software
    prepare_common_command
    get_system_version
    show_tcp_listening

    # 可选函数
    set_memory_swap_to_4GB
    set_ipv6_disable

    # 安装 Docker
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash

    # 安装 MySQL
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/mysql.sh' | bash

    # 安装 Redis
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/redis.sh' | bash

    # 安装 Nginx
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

    # 安装 PHP
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/php.sh' | bash

    # 安装 Shadowsocks
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks.sh' | bash

    # 安装 V2Ray
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash

    # 配置 WEB 站点
    wget -O- --timeout=10 --no-cache \
    'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/config.sh' | bash



