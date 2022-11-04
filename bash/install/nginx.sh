#!/bin/bash

# Nginx
# 开源地址：https://github.com/nginx
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash



# 参数设置：



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
check_command_exist 'nginx' || install_software 'nginx'
nginx -v
if [ $? -ne 0 ]; then
    log_error 'nginx install failed, quit now'
    exit 1
fi



# 启动服务：
systemctl restart 'nginx'
systemctl enable 'nginx'
systemctl status --no-pager 'nginx'

show_tcp_listening


