#!/bin/bash

# Nginx
# 开源地址：https://github.com/nginx
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash



# 参数设置：



# 开始安装：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
if [ $? -eq 0 ]; then
    prepare_common_command
else
    log_error 'My.sh: source failed, quit now'
    return 1
fi

install_software 'nginx'
systemctl enable 'nginx'
systemctl restart 'nginx'
systemctl status --no-pager 'nginx'

nginx -v

