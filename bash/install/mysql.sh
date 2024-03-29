#!/bin/bash

# MySQL
# 开源地址：https://github.com/mysql
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/mysql.sh' | bash



# 参数设置：
function mysql_config_cnf(){
    cat <<EOF
#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[mysqld]
EOF
}

function set_root_password(){
    log_info "set_root_password begin"
    mysql -h 'localhost' -u 'root' -e 'exit' | grep "Access denied for user 'root'@'localhost' (using password: NO)"
    if [ $? -eq 0 ]; then
        log_info "set_root_password by mysql_secure_installation"
        mysql_secure_installation
        exit 1
    fi
    log_info "set_root_password ok"
}

function allow_remote_access(){
    log_info "allow_remote_access begin"
    password='MySQL@33060'
    mysql -h 'localhost' -u 'root' "-p$password" --batch <<EOF
        use mysql;
        alter user 'root' identified with caching_sha2_password by 'MySQL@33060';
        update user set host = '%' where user = 'root';
        select user, host, plugin, authentication_string from user;
        flush privileges;
EOF
    log_info "allow_remote_access ok"
}



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
    # Fix Begin
    # E: Package 'mysql-server' has no installation candidate
    log_info 'mysql-apt-config install begin'

    show_software 'mysql-apt-config'
    if [ $? -ne 0 ]; then
        wget -O '/tmp/mysql-apt-config_0.8.22-1_all.deb' --timeout=10 --no-cache \
        'https://repo.mysql.com/apt/debian/pool/mysql-apt-config/m/mysql-apt-config/mysql-apt-config_0.8.22-1_all.deb'

        # 图形界面操作
        dpkg --configure -a
        dpkg --install '/tmp/mysql-apt-config_0.8.22-1_all.deb'
        update_software
    fi

    show_software 'mysql-apt-config'
    if [ $? -ne 0 ]; then
        log_error 'mysql-server install failed, quit now'
        exit 1
    fi

    log_info 'mysql-apt-config install end'
    # Fix End
fi

check_command_exist 'mysqld' || install_software 'mysql-server'
mysqld --version
if [ $? -ne 0 ]; then
    log_error 'mysql-server install failed, quit now'
    exit 1
fi

set_root_password
allow_remote_access
mysql_config_cnf > '/etc/mysql/mysql.conf.d/mysqld.cnf'



# 启动服务：
systemctl restart 'mysql'
systemctl enable 'mysql'
systemctl status --no-pager 'mysql'

show_tcp_listening


