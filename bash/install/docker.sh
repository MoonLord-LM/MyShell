#!/bin/bash

# Docker
# 开源地址：https://github.com/docker
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash



# 参数设置：



# 开始安装：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
install_common_command

install_software 'docker'
systemctl enable 'docker'
systemctl restart 'docker'
systemctl status --no-pager 'docker'

docker run 'hello-world'
docker version


