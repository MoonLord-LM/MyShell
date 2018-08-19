#!/bin/bash
source ./My.sh

# MySQL 5.7.23 在线安装
# sudo chmod -R 777 ./ && sudo sh ./mysql_5.7.23.sh --install
# sudo chmod -R 777 ./ && sudo sh ./mysql_5.7.23.sh --reinstall
# sudo chmod -R 777 ./ && sudo sh ./mysql_5.7.23.sh --clean_cache


# 参数设置
user_root_password="Ecs1312357@MySQL"
mysql_version='5.7.23'
mysql_port='5723'
mysql_source_url='https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.23.tar.gz'



# 选项解析
service_name="mysqld$mysql_port"
source_name="mysql-$mysql_version"
install_dir="/usr/local/mysql/mysql-$mysql_version"

if [ "$1" == "--reinstall" ];then
    sudo systemctl stop "${service_name}.service"
    sudo systemctl disable "${service_name}.service"
    sudo rm -rf "/usr/lib/systemd/system/${service_name}.service"
    sudo rm -rf "$install_dir"
    sudo systemctl daemon-reload
elif [ "$1" == "--clean_cache" ]; then
    rm -rf "./$source_name"
    rm -rf "./$source_name.tar.gz"
    show_disk_usage '$install_dir'
    return 0
elif [ "$1" == "--install" ]; then
    if [ -d "$install_dir" ];then
        die '[ Error ] install_dir exists!'
    fi
else
    echo && \
    info 'options:' && \
    echo && \
    info "    --install      install $source_name" && \
    info "                   default install dir: $install_dir" && \
    info '                   if already installed, do nothing' && \
    echo && \
    info "    --reinstall    reinstall $source_name" && \
    info "                   default install dir: $install_dir" && \
    info '                   if already installed, delete the existed' && \
    echo && \
    info '    --clean_cache  delete cached files' && \
    info '                   use this to save disk space' && \
    info '                   it will slow down future installations' && \
    echo && \
    die 'require one option'
fi



# 开始安装
rm -rf '/etc/my.cnf'
rm -rf '/var/log/mysql.log'

prepare_source "$mysql_source_url"
install_require 'bison'
install_require 'libaio-devel'
install_require 'ncurses-devel'
install_require 'openssl-devel'

add_user_group 'mysql' 'MySQL Server' '/usr/local/mysql'
set_user_dir 'mysql' "$install_dir"
set_user_dir 'mysql' "$install_dir/data"
set_user_dir 'mysql' "$install_dir/ssl"
set_user_file 'mysql' "$install_dir/mysql_error.log"
set_user_file 'mysql' "$install_dir/mysql_general.log"
set_user_file 'mysql' "$install_dir/mysql_slow_query.log"
set_user_file 'mysql' "$install_dir/mysql.sock"
set_user_file 'mysql' "$install_dir/mysqlx.sock"
set_user_file 'mysql' "$install_dir/my.cnf"

set_memory_swap

# https://dev.mysql.com/doc/refman/5.7/en/source-configuration-options.html
cd "$source_name"
cmake \
 -DMYSQL_TCP_PORT="$mysql_port" \
 -DMYSQLX_TCP_PORT="1$mysql_port" \
 -DCMAKE_INSTALL_PREFIX="$install_dir" \
 -DMYSQL_DATADIR="$install_dir/data" \
 -DSYSCONFDIR="$install_dir" \
 -DMYSQL_UNIX_ADDR="$install_dir/mysql.sock" \
 -DMYSQLX_UNIX_ADDR="$install_dir/mysqlx.sock" \
 -DWITH_SYSTEMD=1 \
 -DSYSTEMD_SERVICE_NAME="$service_name" \
 -DSYSTEMD_PID_DIR="$install_dir" \
 -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
 -DWITH_EXAMPLE_STORAGE_ENGINE=1 \
 -DWITH_FEDERATED_STORAGE_ENGINE=1 \
 -DWITH_PARTITION_STORAGE_ENGINE=1 \
 -DWITH_INNODB_MEMCACHED=1 \
 -DENABLED_LOCAL_INFILE=1 \
 -DDOWNLOAD_BOOST=1 \
 -DWITH_BOOST=./boost \
 -DDEFAULT_CHARSET='utf8mb4' \
 -DDEFAULT_COLLATION='utf8mb4_unicode_ci' \
 -DCOMPILATION_COMMENT="compiled at `cat '/etc/redhat-release'`" \
 2>&1 | tee 'cmake.log'
make -j `grep 'processor' '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

# https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html
# https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html
# https://dev.mysql.com/doc/refman/5.7/en/program-variables.html
# https://dev.mysql.com/doc/refman/5.7/en/using-encrypted-connections.html
cd "$install_dir"
cat << EOF > "my.cnf"
[mysqld]
port=$mysql_port
basedir=$install_dir
datadir=$install_dir/data
socket=$install_dir/mysql.sock
pid_file=$install_dir/${service_name}.pid

lc_messages_dir=$install_dir/share
log_error=$install_dir/mysql_error.log
general_log=1
general_log_file=$install_dir/mysql_general.log
slow_query_log=1
slow_query_log_file=$install_dir/mysql_slow_query.log
long_query_time=5

character_set_server='utf8mb4'
collation_server='utf8mb4_unicode_ci'
init_connect='set names utf8mb4; set collation_connection = utf8mb4_unicode_ci;'

default_time_zone='+8:00'
explicit_defaults_for_timestamp=1
default_storage_engine='InnoDB'
default_tmp_storage_engine='InnoDB'

connect_timeout=10
wait_timeout=60
interactive_timeout=60
net_read_timeout=120
net_write_timeout=120
lock_wait_timeout=120
max_connections=200
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=120

ssl_ca=$install_dir/ssl/ca.pem 
ssl_cert=$install_dir/ssl/server-cert.pem 
ssl_key=$install_dir/ssl/server-key.pem

[client]
host=localhost
port=$mysql_port
socket=$install_dir/mysql.sock
user=root
password=$user_root_password
default_character_set='utf8mb4'

ssl_ca=$install_dir/ssl/ca.pem
ssl_cert=$install_dir/ssl/client-cert.pem
ssl_key=$install_dir/ssl/client-key.pem
EOF

# https://dev.mysql.com/doc/refman/5.7/en/mysql-ssl-rsa-setup.html
cd "$install_dir/bin"
./mysql_ssl_rsa_setup \
 --datadir="$install_dir/ssl" \
 --uid='mysql' \
 2>&1 | tee 'mysql_ssl_rsa_setup.log'
 
# https://dev.mysql.com/doc/refman/5.7/en/server-options.html
cd "$install_dir/bin"
./mysqld \
 --defaults-file="$install_dir/my.cnf" \
 --user='mysql' \
 --initialize \
 2>&1 | tee 'mysqld_initialize.log'

backup_file "../usr/lib/systemd/system/${service_name}.service"
cp -f "../usr/lib/systemd/system/${service_name}.service" "/usr/lib/systemd/system/${service_name}.service"

sed -i "s/mysqld.pid/${service_name}.pid/g" "/usr/lib/systemd/system/${service_name}.service"
modify_config_file "/usr/lib/systemd/system/${service_name}.service" 'LimitNOFILE = ' 'LimitNOFILE = 65535'

systemctl enable "${service_name}.service"
systemctl daemon-reload
systemctl start "${service_name}.service"
systemctl status -l "${service_name}.service"

tmp=`cat $install_dir/${service_name}.pid`
cat "/proc/$tmp/limits"

temporary_password=`grep 'temporary password' "$install_dir/mysql_error.log"`
temporary_password="${temporary_password##*root@localhost: }"
echo "temporary_password: $temporary_password"
cd "$install_dir/bin"
./mysqladmin -u 'root' "-p$temporary_password" password "$user_root_password"

cd "$install_dir/bin"
./mysql -u 'root' "-p$user_root_password" << EOF
    status;
EOF
./mysql  << EOF
    show databases;
    -- show variables like "%character_set%";
    -- show variables like "%collation%";
    -- show variables like "%timeout%";
    -- show variables like "%log%";
    -- show variables like "%engine%";
    -- show variables like "%time_zone%";
EOF

./mysql  << EOF
    grant all on *.* to 'root'@'%' identified by '$user_root_password' require none with grant option;
    flush privileges;
    select user,host,ssl_type from mysql.user;
    -- grant all on *.* to 'root'@'%' identified by '$user_root_password' require ssl with grant option;
    -- alter user 'root'@'%' require ssl;
    -- alter user 'root'@'%' require none;
EOF

show_listen