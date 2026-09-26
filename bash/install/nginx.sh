#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

# Nginx
# https://github.com/nginx





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist 'nginx'
if [ $? -eq 0 ]; then
    log_info 'nginx already installed, quit now'
    exit 0
fi

install_software 'nginx'

nginx -v
if [ $? -ne 0 ]; then
    log_error 'nginx install failed, quit now'
    exit 1
fi





# ———————————————————————— Start ————————————————————————
systemctl restart 'nginx'
systemctl enable 'nginx'
systemctl status --no-pager 'nginx'

show_tcp_listening
