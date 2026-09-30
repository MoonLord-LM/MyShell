#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

# Nginx
# https://github.com/nginx





# ———————————————————————— Config ————————————————————————
nginx_ssl_key='/etc/nginx/ssl/server-key.pem'
nginx_ssl_cert='/etc/nginx/ssl/server-cert.pem'

run_uid_gid='www-data:www-data'





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi
prepare_common_command





# ———————————————————————— Install ————————————————————————
check_command_exist 'nginx'
if [ $? -eq 0 ]; then
    log_info 'nginx already installed, quit now'
    exit 0
fi

install_software 'nginx'
{
    if_error_then_exit 'nginx install failed, quit now'
}

nginx -v
{
    if_error_then_exit 'nginx version check failed, quit now'
}

generate_ssl_cert 'Nginx' "$nginx_ssl_key" "$nginx_ssl_cert"
{
    if_error_then_exit 'nginx ssl cert generate failed, quit now'
}





# ———————————————————————— Start ————————————————————————
systemctl restart 'nginx'
systemctl enable 'nginx'
systemctl status --no-pager 'nginx'

show_tcp_listening
