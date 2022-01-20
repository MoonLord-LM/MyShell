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
install_software 'php-cli'
install_software 'php-fpm'
install_software 'php-mysql'
install_software 'php-pgsql'
install_software 'php-odbc'
install_software 'php-sqlite3'
install_software 'php-curl'
install_software 'php-json'
install_software 'php-mbstring'
install_software 'php-gd'
install_software 'php-bcmath'
install_software 'php-zip'

check_system_is_ubuntu
if [ $? -eq 0 ]; then
    install_software 'php-redis'
    install_software 'php-memcached'
    install_software 'php-yaml'
else
    check_system_is_debian
    if [ $? -eq 0 ]; then
        install_software 'php-redis'
        install_software 'php-memcached'
        install_software 'php-yaml'
    fi
fi

php -v
if [ $? -ne 0 ]; then
    log_error 'php install failed, quit now'
    exit 1
fi

php_fpm_service_file=$(find '/usr/lib/systemd/system/' -type f 2> '/dev/null' | grep 'php' | grep 'fpm.service$')
if [ "$php_fpm_service_file" == '' ]; then
    log_error 'php-fpm install failed, quit now'
    exit 1
fi
log_info "php_fpm_service_file: $php_fpm_service_file"

php_fpm_service=${php_fpm_service_file/#'/usr/lib/systemd/system/'/''}
php_fpm_service=${php_fpm_service/%'.service'/''}
if [ "$php_fpm_service" == '' ]; then
    log_error 'php-fpm install failed, quit now'
    exit 1
fi
log_info "php_fpm_service: $php_fpm_service"



# 启动服务：
systemctl enable "$php_fpm_service"
systemctl restart "$php_fpm_service"
systemctl status --no-pager "$php_fpm_service"


