#!/bin/bash

# Docker
# 开源地址：https://github.com/docker
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash



# 参数设置：



# 开始安装：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
if [ $? -eq 0 ]; then
    prepare_common_command
else
    log_error 'My.sh: source failed, quit now'
    return 1
fi

check_command_exist 'docker' || install_software 'docker'
docker version

systemctl enable 'docker'
systemctl restart 'docker'
systemctl status --no-pager 'docker'

docker run 'hello-world'


