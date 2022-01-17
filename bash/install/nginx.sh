#!/bin/bash

# Nginx
# 开源地址：https://github.com/nginx
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash



# 参数设置：



# 加载函数：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
install_software 'nginx'
nginx -v

systemctl enable 'nginx'
systemctl restart 'nginx'
systemctl status --no-pager 'nginx'


