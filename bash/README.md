
# MyShell
A function library for the Linux Shell.  
Linux Shell 常用脚本和函数.  

## [测试环境]
Ubuntu 20.04 / Debian 11 / CentOS 8.2  

## [使用方法]

    # 加载函数
    source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )

    # 安装 Docker
    wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash

    # 安装 OpenJDK
    wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/openjdk.sh' | bash

    # 安装 Nginx
    wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

    # 安装 PHP
    wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/php.sh' | bash

    # 安装 Shadowsocks
    wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks.sh' | bash

    # 配置 WEB 站点
    wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/config.sh' | bash


