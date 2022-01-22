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
check_system_is_debian
if [ $? -eq 0 ]; then
    # Fix Bug
    # E: Package 'mysql-server' has no installation candidate
    # http://repo.mysql.com/apt/debian/pool/
    wget -O '/tmp/mysql-server_8.0.28-1debian10_amd64.deb' --timeout=10 --no-cache 'http://repo.mysql.com/apt/debian/pool/mysql-8.0/m/mysql-community/mysql-server_8.0.28-1debian10_amd64.deb'
    apt install -y '/tmp/mysql-server_8.0.28-1debian10_amd64.deb'
    # Fix End
fi

check_command_exist 'mysqld' || install_software 'mysql-server'
mysqld --version
if [ $? -ne 0 ]; then
    log_error 'mysql-server install failed, quit now'
    exit 1
fi



# 启动服务：
mysql_service_file=$(find '/usr/lib/systemd/system/' -type f 2> '/dev/null' | grep 'mysql' | grep -v '@')
if [ "$mysql_service_file" == '' ]; then
    log_error 'mysql install failed, quit now'
    exit 1
fi
log_info "mysql_service_file: $mysql_service_file"

mysql_service=${mysql_service_file/#'/usr/lib/systemd/system/'/''}
if [ "$mysql_service" == '' ]; then
    log_error 'mysql install failed, quit now'
    exit 1
fi
log_info "mysql_service: $mysql_service"

systemctl enable "$mysql_service"
systemctl restart "$mysql_service"
systemctl status --no-pager "$mysql_service"


