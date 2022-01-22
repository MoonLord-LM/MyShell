#!/bin/bash

# MySQL
# 开源地址：https://github.com/mysql
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/mysql.sh' | bash



# 参数设置：



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
install_software 'mysql-server'
nginx -v
if [ $? -ne 0 ]; then
    log_error 'mysql-server install failed, quit now'
    exit 1
fi



# 启动服务：
systemctl enable 'mysql-server'
systemctl restart 'mysql-server'
systemctl status --no-pager 'mysql-server'


