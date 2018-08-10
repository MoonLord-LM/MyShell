#!/bin/bash
source ./My.sh

# MySQL 8.0.12 在线安装
# sudo chmod -R 777 ./ && sudo sh ./mysql_8.0.12.sh


# 参数设置
user_root_password="Ecs1312357@MySQL"
mysql_version='8.0.12'
mysql_port='8012'
mysql_source_url='https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.12.tar.gz'


# 开始安装
service_name="mysqld$mysql_port"
source_dir="mysql-$mysql_version"
install_dir="/usr/local/mysql/mysql-$mysql_version"

rm -rf "/etc/my.cnf"
rm -rf "/var/log/mysql.log"
rm -rf "/var/log/message"

if [ -d "$install_dir" ];then
    die "[ Error ] install_dir: '$install_dir' is not empty!"
    # sudo systemctl stop "mysqld8012.service"
    # sudo systemctl disable "mysqld8012.service"
    # sudo rm -rf "/usr/local/mysql/mysql-8.0.12"
fi

prepare_source "$mysql_source_url"
install_require 'bison'
install_require 'libaio-devel'
install_require 'ncurses-devel'
install_require 'openssl-devel'

add_user_group 'mysql' 'MySQL Server' '/usr/local/mysql'
set_user_dir 'mysql' "$install_dir"
set_user_dir 'mysql' "$install_dir/data"
set_user_file 'mysql' "$install_dir/mysql_error.log"
set_user_file 'mysql' "$install_dir/mysql_general.log"
set_user_file 'mysql' "$install_dir/mysql_slow_query.log"
set_user_file 'mysql' "$install_dir/mysql.sock"
set_user_file 'mysql' "$install_dir/mysqlx.sock"
set_user_file 'mysql' "$install_dir/my.cnf"

set_memory_swap

# https://dev.mysql.com/doc/refman/8.0/en/source-configuration-options.html
cd "$source_dir"
cmake \
 -DMYSQL_TCP_PORT="$mysql_port" \
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
 -DWITH_INNODB_MEMCACHED=1 \
 -DENABLED_LOCAL_INFILE=1 \
 -DDOWNLOAD_BOOST=1 \
 -DWITH_BOOST=./boost \
 -DCOMPILATION_COMMENT="`cat '/etc/redhat-release'`" \
 2>&1 | tee 'cmake.log'
make -j `grep processor '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html
cat <<EOF > "$install_dir/my.cnf"
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
collation_server='utf8mb4_0900_ai_ci'
init_connect='set names utf8mb4; set collation_connection = utf8mb4_0900_ai_ci;'

default-time-zone='+8:00'
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

[client]
host=localhost
port=$mysql_port
socket=$install_dir/mysql.sock
user=root
password=$user_root_password
character_set_client='utf8mb4'
EOF

# https://dev.mysql.com/doc/refman/8.0/en/server-options.html
cd "$install_dir/bin"
./mysqld \
 --defaults-file="$install_dir/my.cnf" \
 --user='mysql' \
 --initialize \
 2>&1 | tee 'mysqld_initialize.log'

# https://dev.mysql.com/doc/refman/8.0/en/mysql-ssl-rsa-setup.html
./mysql_ssl_rsa_setup \
 --datadir="$install_dir/data" \
 --uid='mysql' \
 2>&1 | tee 'mysql_ssl_rsa_setup.log'

backup_file "../usr/lib/systemd/system/${service_name}.service"
cp -f "../usr/lib/systemd/system/${service_name}.service" "/usr/lib/systemd/system/${service_name}.service"

systemctl enable "${service_name}.service"
systemctl daemon-reload
systemctl start "${service_name}.service"
systemctl status -l "${service_name}.service"