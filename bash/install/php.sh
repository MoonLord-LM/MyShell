#!/bin/bash

# Nginx
# 开源地址：https://github.com/php
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/php.sh' | bash



# 参数设置：



# 加载函数：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
install_software 'php-fpm'
install_software 'php-mysql'
install_software 'php-pgsql'
nginx -v
if [ $? -ne 0 ]; then
    log_error 'php install failed, quit now'
    exit 1
fi



# 启动服务
systemctl enable 'php-fpm'
systemctl restart 'php-fpm'
systemctl status --no-pager 'php-fpm'


