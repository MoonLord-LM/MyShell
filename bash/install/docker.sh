#!/bin/bash

# Docker
# 开源地址：https://github.com/docker
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash



# 参数设置：



# 开始安装：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi

check_command_exist 'docker' || install_software 'docker'
docker version

systemctl enable 'docker'
systemctl restart 'docker'
systemctl status --no-pager 'docker'

docker run 'hello-world'


