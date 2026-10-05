#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/mysql.sh' | bash

# export MYSQL_PASSWORD="<password>"
# apt remove -y mysql-community-server-core && apt purge -y mysql-apt-config

# MySQL
# https://github.com/mysql/mysql-server





# ———————————————————————— Config ————————————————————————
mysql_apt_config_url='https://dev.mysql.com/get/mysql-apt-config_0.8.40-1_all.deb'
mysql_apt_config_select='mysql-8.4-lts'

mysql_conf_file='/etc/mysql/conf.d/mysql.cnf'
mysql_ssl_key='/etc/mysql/ssl/server-key.pem'
mysql_ssl_cert='/etc/mysql/ssl/server-cert.pem'

mysql_user='admin'
mysql_server_port=13306
mysql_password="${MYSQL_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"
mysql_password_sql_escaped=$(printf '%s' "$mysql_password" | sed -e 's/\\/\\\\/g' -e "s/'/''/g")

run_uid_gid='mysql:mysql'

function mysql_config_cnf(){
    cat <<EOF
[mysqld]
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
datadir = /var/lib/mysql
log-error = /var/log/mysql/error.log

bind-address = *
port = $mysql_server_port
ssl-key = $mysql_ssl_key
ssl-cert = $mysql_ssl_cert
tls_version = TLSv1.2,TLSv1.3

require_secure_transport = ON
mysqlx = OFF

plugin-load-add = connection_control.so
connection_control_failed_connections_threshold = 5
connection_control_min_connection_delay = 2147483000
connection_control_max_connection_delay = 2147483000
EOF
}

function allow_remote_access(){
    mysql -h 'localhost' -u 'root' --batch <<EOF
        create user if not exists '$mysql_user'@'%' identified by '$mysql_password_sql_escaped';
        alter user '$mysql_user'@'%' identified by '$mysql_password_sql_escaped';
        grant all privileges on *.* to '$mysql_user'@'%' with grant option;
        select user, host, plugin from mysql.user;
        flush privileges;
EOF
    {
        if_error_then_exit 'allow_remote_access failed, quit now'
    }
}





# ———————————————————————— Init ————————————————————————
tmp_file="/tmp/MyShell_My.sh_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.sh"
wget -O "$tmp_file" --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh'
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: download failed, quit now' && echo -ne '\e[0m'
    rm -f "$tmp_file"
    exit 1
fi
source "$tmp_file"
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    rm -f "$tmp_file"
    exit 1
fi
rm -f "$tmp_file"
prepare_common_command





# ———————————————————————— Install ————————————————————————
check_command_exist 'mysqld'
if [ $? -eq 0 ]; then
    log_info 'mysql already installed, quit now'
    exit 0
fi

log_warn 'if $MYSQL_PASSWORD is not set, a random password will be generated:'
log_warn 'export MYSQL_PASSWORD="<password>"'

search_software 'mysql-apt-config'
if [ $? -ne 0 ]; then
    echo "mysql-apt-config mysql-apt-config/select-server select $mysql_apt_config_select" | debconf-set-selections

    tmp_file="/tmp/mysql-apt-config_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.deb"
    wget -O "$tmp_file" --timeout=120 --no-cache "$mysql_apt_config_url"
    {
        if_error_then_exit 'mysql-apt-config download failed, quit now'
    }

    dpkg --configure -a
    dpkg --install "$tmp_file"
    update_software

    rm -f "$tmp_file"
fi

search_software 'mysql-apt-config'
{
    if_error_then_exit 'mysql-apt-config install failed, quit now'
}

install_software 'mysql-community-server'
{
    if_error_then_exit 'mysql-community-server install failed, quit now'
}

mysqld --version
{
    if_error_then_exit 'mysql-community-server version check failed, quit now'
}

generate_ssl_cert 'MySQL' "$mysql_ssl_key" "$mysql_ssl_cert" "$run_uid_gid"
{
    if_error_then_exit 'mysql ssl cert generate failed, quit now'
}

update_file "$mysql_conf_file" "$(mysql_config_cnf)"
{
    if_error_then_exit 'mysql config file write failed, quit now'
}

mysqld --validate-config
{
    if_error_then_exit 'mysql-community-server config failed, quit now'
}

allow_remote_access

mysql_server_ip=$(get_system_ip)
log_attention "mysql server ip: ${mysql_server_ip}"
log_attention "mysql server port: ${mysql_server_port}"
log_attention "mysql user: ${mysql_user}"
log_attention "mysql password: ${mysql_password}"
log_attention "mysql ssl cert: ${mysql_ssl_cert}"





# ———————————————————————— Start ————————————————————————
systemctl restart 'mysql'
systemctl enable 'mysql'
systemctl status --no-pager 'mysql'

show_tcp_listening
