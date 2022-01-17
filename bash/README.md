
# MyShell
A function library for the Linux Shell.  
Linux Shell 常用脚本和函数.  

## [测试环境]
Ubuntu 20.04 / Debian 11 / Centos 8  

## [使用方法]

    # 加载函数
    source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )

    # 安装 Docker
    wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash

    # 安装 Nginx
    wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

    # 安装 Shadowsocks
    wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks-libev.sh' | bash


