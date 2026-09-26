#!/bin/bash

# MySQL
# 开源地址：https://github.com/mysql/mysql-server
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/mysql.sh' | bash



# 参数设置：
mysql_apt_config_url='https://repo.mysql.com/apt/debian/pool/mysql-apt-config/m/mysql-apt-config/mysql-apt-config_0.8.40-1_all.deb'
mysql_apt_config_select='mysql-8.4-lts'

mysql_conf_file='/etc/mysql/mysql.conf.d/mysqld.cnf'
mysql_ssl_key='/etc/mysql/ssl/server-key.pem'
mysql_ssl_cert='/etc/mysql/ssl/server-cert.pem'

mysql_user='admin'
mysql_server_port=13306
mysql_password=$(head -c 32 '/dev/urandom' | base64 -w 0)

function mysql_config_cnf(){
    cat <<EOF
[mysqld]
bind-address = *
port = $mysql_server_port
ssl-key = $mysql_ssl_key
ssl-cert = $mysql_ssl_cert

require_secure_transport = ON
mysqlx = OFF

plugin-load-add = connection_control.so
connection_control_failed_connections_threshold = 5
connection_control_min_connection_delay = 2147483000
connection_control_max_connection_delay = 2147483000
EOF
}

function mysql_gen_ssl_cert(){
    log_info 'mysql_gen_ssl_cert begin'
    mkdir -p $(dirname "$mysql_ssl_key")
    openssl req -newkey rsa:4096 -nodes -keyout "$mysql_ssl_key" -x509 -days 365000 -out "$mysql_ssl_cert" -subj '/CN=MySQL'
    if [ $? -ne 0 ]; then
        log_error 'mysql_gen_ssl_cert failed, quit now'
        exit 1
    fi

    chown mysql:mysql "$mysql_ssl_key" "$mysql_ssl_cert"
    chmod 600 "$mysql_ssl_key"
    log_info 'mysql_gen_ssl_cert ok'
}

function allow_remote_access(){
    log_info "allow_remote_access begin"
    mysql -h 'localhost' -u 'root' --batch <<EOF
        create user if not exists '$mysql_user'@'%' identified by '$mysql_password';
        alter user '$mysql_user'@'%' identified by '$mysql_password';
        grant all privileges on *.* to '$mysql_user'@'%' with grant option;
        select user, host, plugin from mysql.user;
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
show_software 'mysql-apt-config'
if [ $? -ne 0 ]; then
    # debconf 预置答案，安装时不会弹出版本选择界面
    echo "mysql-apt-config mysql-apt-config/select-server select $mysql_apt_config_select" | debconf-set-selections

    tmp_file="/tmp/mysql-apt-config_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.deb"
    wget -O "$tmp_file" --timeout=120 --no-cache "$mysql_apt_config_url"

    dpkg --configure -a
    dpkg --install "$tmp_file"
    update_software

    rm -f "$tmp_file"
fi

show_software 'mysql-apt-config'
if [ $? -ne 0 ]; then
    log_error 'mysql-apt-config install failed, quit now'
    exit 1
fi

check_command_exist 'mysqld' || install_software 'mysql-community-server'
mysqld --version
if [ $? -ne 0 ]; then
    log_error 'mysql-community-server install failed, quit now'
    exit 1
fi

mysql_gen_ssl_cert

backup_file "$mysql_conf_file"
mysql_config_cnf > "$mysql_conf_file"

allow_remote_access

mysql_server_ip=$(hostname -I | awk '{print $1}')
log_attention "mysql server ip: ${mysql_server_ip}"
log_attention "mysql server port: ${mysql_server_port}"
log_attention "mysql user: ${mysql_user}"
log_attention "mysql password: ${mysql_password}"
log_attention "mysql ssl cert: ${mysql_ssl_cert}"



# 启动服务：
systemctl restart 'mysql'
systemctl enable 'mysql'
systemctl status --no-pager 'mysql'

show_tcp_listening


