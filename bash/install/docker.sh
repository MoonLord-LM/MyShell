#!/bin/bash

# Docker
# 开源地址：https://github.com/docker
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash



# 参数设置：



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
check_command_exist 'docker' || install_software 'docker.io'
docker version
if [ $? -ne 0 ]; then
    log_error 'docker install failed, quit now'
    exit 1
fi



# 启动服务：
systemctl enable 'docker'
systemctl restart 'docker'
systemctl status --no-pager 'docker'

docker run 'hello-world'

log_info 'docker images:' && docker images

log_info 'docker ps -a:' && docker ps -a


