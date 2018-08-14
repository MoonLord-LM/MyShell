#!/bin/bash
source ./My.sh

# PHP 5.6.37 在线安装
# sudo chmod -R 777 ./ && sudo sh ./php_5.6.37.sh
# sudo chmod -R 777 ./ && sudo sh ./php_5.6.37.sh --delete_exist


# 参数设置
php_version='5.6.37'
php_port='5637'
php_source_url='http://cn2.php.net/distributions/php-5.6.37.tar.gz'


# 开始安装
service_name="php-fpm-$php_port"
source_dir="php-$php_version"
install_dir="/usr/local/php/php-$php_version"

if [ "$1" == "--delete_exist" ];then
    sudo rm -rf "/etc/init.d/$service_name"
    sudo rm -rf "$install_dir"
fi

rm -rf '/etc/php.ini'

if [ -d "$install_dir" ];then
    die '[ Error ] install_dir exists!'
fi

prepare_source "$php_source_url"
install_require "bzip2-devel"
install_require "freetype-devel"
install_require "libcurl-devel"
install_require "libjpeg-devel"
install_require "libmcrypt-devel"
install_require "libpng-devel"
install_require "libxml2-devel"
install_require "libxslt-devel"
install_require "openssl-devel"
install_require "postgresql-devel"

add_user_group 'php' 'PHP Server' '/usr/local/php'
set_user_dir 'php' "$install_dir"

cd "$source_dir"
./configure \
 --prefix="$install_dir" \
 --with-config-file-path="$install_dir" \
 --enable-fpm \
 --with-fpm-user='php' \
 --with-fpm-group='php' \
  \
 --enable-bcmath \
 --enable-ftp \
 --enable-gd-native-ttf \
 --enable-inline-optimization \
 --enable-libxml \
 --enable-mbregex \
 --enable-mbstring \
 --enable-opcache \
 --enable-pcntl \
 --enable-shmop \
 --enable-soap \
 --enable-sockets \
 --enable-sysvsem \
 --enable-xml \
 --enable-zip \
  \
 --with-bz2 \
 --with-curl \
 --with-freetype-dir \
 --with-gd \
 --with-gettext \
 --with-iconv \
 --with-jpeg-dir \
 --with-kerberos \
 --with-libdir=lib64 \
 --with-libxml-dir \
 --with-mcrypt \
 --with-mhash \
 --with-mysql \
 --with-mysqli \
 --with-openssl \
 --with-pcre-regex \
 --with-pdo-mysql \
 --with-pdo-pgsql \
 --with-pdo-sqlite \
 --with-pear \
 --with-pgsql \
 --with-png-dir \
 --with-xmlrpc \
 --with-xsl \
 --with-zlib \
 2>&1 | tee 'configure.log'
make -j `grep processor '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

tmp="$install_dir/etc/php.ini-production"
cp -f 'php.ini-production' "$tmp"
tmp="$install_dir/etc/php.ini-development"
cp -f 'php.ini-development' "$tmp"
modify_config_file "$tmp" 'error_log =' 'error_log = php.error.log'
modify_config_file "$tmp" 'log_errors_max_len =' 'log_errors_max_len = 0'
modify_config_file "$tmp" 'date.timezone =' 'date.timezone = "Asia/Shanghai"'
modify_config_file "$tmp" 'upload_max_filesize =' 'upload_max_filesize = 100M'
modify_config_file "$tmp" 'max_file_uploads =' 'max_file_uploads = 100'
modify_config_file "$tmp" 'post_max_size =' 'post_max_size = 100M'
modify_config_file "$tmp" 'max_input_time =' 'max_input_time = 120'
modify_config_file "$tmp" 'max_execution_time =' 'max_execution_time = 120'
modify_config_file "$tmp" 'opcache.enable=' 'opcache.enable=1'
modify_config_file "$tmp" 'opcache.enable_cli=' 'opcache.enable_cli=1'
modify_config_file "$tmp" 'opcache.validate_timestamps=' 'opcache.validate_timestamps=1'
modify_config_file "$tmp" 'opcache.revalidate_freq=' 'opcache.revalidate_freq=0'
modify_config_file "$tmp" 'opcache.memory_consumption=' 'opcache.memory_consumption=128'
modify_config_file "$tmp" 'opcache.interned_strings_buffer=' 'opcache.interned_strings_buffer=8'
modify_config_file "$tmp" 'opcache.max_accelerated_files=' 'opcache.max_accelerated_files=100000'
cp -f "$tmp" "$install_dir/php.ini"

tmp="$install_dir/etc/php-fpm.conf.default"
sed -i "s#run/#./#g" "$tmp"
modify_config_file "$tmp" 'pid = ' "pid = $service_name.pid"
modify_config_file "$tmp" 'listen = ' "listen = 127.0.0.1:$php_port"
modify_config_file "$tmp" 'listen.allowed_clients =' 'listen.allowed_clients = 127.0.0.1'
modify_config_file "$tmp" 'error_log =' 'error_log = php-fpm.error.log'
modify_config_file "$tmp" 'access.log = ' 'access.log = php-fpm.$pool.access.log'
cp -f "$tmp" "$install_dir/php-fpm.conf"

tmp="$install_dir/etc/init.d.php-fpm"
cp -f 'sapi/fpm/init.d.php-fpm' "$tmp"
sed -i "s#/etc/#/#g" "$tmp"
sed -i "s#/var/run/#/#g" "$tmp"
cp -f "$tmp" "/etc/init.d/$service_name"
chmod +x "/etc/init.d/$service_name"
chkconfig "$service_name" on

service "$service_name" start

"$install_dir/bin/php" -v
"$install_dir/bin/php" -m
"$install_dir/sbin/php-fpm" -v

ps -aux | grep "php"

show_listen