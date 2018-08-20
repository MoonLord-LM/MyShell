#!/bin/bash
source ./My.sh

# PHP 5.6.37 在线安装
# sudo chmod -R 777 ./ && sudo sh ./php_5.6.37.sh --install
# sudo chmod -R 777 ./ && sudo sh ./php_5.6.37.sh --reinstall
# sudo chmod -R 777 ./ && sudo sh ./php_5.6.37.sh --clean_cache


# 参数设置
php_version='5.6.37'
php_port='5637'
php_source_url='http://cn2.php.net/distributions/php-5.6.37.tar.gz'



# 选项解析
service_name="php-fpm-$php_port"
source_name="php-$php_version"
install_dir="/usr/local/php/php-$php_version"

if [ "$1" == "--reinstall" ]; then
    sudo service "$service_name" stop
    sudo chkconfig "$service_name" off
    sudo rm -rf "/etc/init.d/$service_name"
    sudo rm -rf "$install_dir"
    sudo systemctl daemon-reload
elif [ "$1" == "--clean_cache" ]; then
    sudo rm -rf "./$source_name"
    sudo rm -rf "./$source_name.tar.gz"
    show_disk_usage "$install_dir"
    exit 0
elif [ "$1" == "--install" ]; then
    if [ -d "$install_dir" ]; then
        die '[ Error ] install_dir exists!'
        exit 1
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
    info '                   delete the existed, and redo installation' && \
    echo && \
    info '    --clean_cache  delete cached files' && \
    info '                   use this to save disk space' && \
    info '                   it will slow down the future installations' && \
    echo && \
    die 'require one option'
    exit 1
fi



# 开始安装
rm -rf '/etc/php.ini'

prepare_source "$php_source_url"
install_require 'bzip2-devel'
install_require 'freetype-devel'
install_require 'libcurl-devel'
install_require 'libjpeg-devel'
install_require 'libmcrypt-devel'
install_require 'libpng-devel'
install_require 'libxml2-devel'
install_require 'libxslt-devel'
install_require 'openssl-devel'
install_require 'postgresql-devel'

add_user_group 'php' 'PHP Server' '/usr/local/php'
set_user_dir 'php' "$install_dir"
set_user_file 'php' "$install_dir/php.error.log"
set_user_file 'php' "$install_dir/php-fpm.error.log"
set_user_file 'php' "$install_dir/php-fpm.access.log"

cd "$source_name"
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
make -j `grep 'processor' '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

rm -rf "$install_dir/var"

cp -f 'php.ini-production' "$install_dir/etc/php.ini-production"
cp -f 'php.ini-development' "$install_dir/etc/php.ini-development"
cp -f 'php.ini-development' "$install_dir/php.ini"
modify_config_file "$install_dir/php.ini" 'error_log = syslog' "error_log = $install_dir/php.error.log"
modify_config_file "$install_dir/php.ini" 'log_errors_max_len =' 'log_errors_max_len = 0'
modify_config_file "$install_dir/php.ini" 'date.timezone =' 'date.timezone = "Asia/Shanghai"'
modify_config_file "$install_dir/php.ini" 'upload_max_filesize =' 'upload_max_filesize = 100M'
modify_config_file "$install_dir/php.ini" 'max_file_uploads =' 'max_file_uploads = 100'
modify_config_file "$install_dir/php.ini" 'post_max_size =' 'post_max_size = 100M'
modify_config_file "$install_dir/php.ini" 'max_input_time =' 'max_input_time = 120'
modify_config_file "$install_dir/php.ini" 'max_execution_time =' 'max_execution_time = 120'
modify_config_file "$install_dir/php.ini" 'opcache.enable=' 'opcache.enable=1'
modify_config_file "$install_dir/php.ini" 'opcache.enable_cli=' 'opcache.enable_cli=1'
modify_config_file "$install_dir/php.ini" 'opcache.validate_timestamps=' 'opcache.validate_timestamps=1'
modify_config_file "$install_dir/php.ini" 'opcache.revalidate_freq=' 'opcache.revalidate_freq=0'
modify_config_file "$install_dir/php.ini" 'opcache.memory_consumption=' 'opcache.memory_consumption=128'
modify_config_file "$install_dir/php.ini" 'opcache.interned_strings_buffer=' 'opcache.interned_strings_buffer=8'
modify_config_file "$install_dir/php.ini" 'opcache.max_accelerated_files=' 'opcache.max_accelerated_files=100000'

modify_config_file "$install_dir/etc/php-fpm.conf.default" 'pid = ' "pid = $install_dir/$service_name.pid"
modify_config_file "$install_dir/etc/php-fpm.conf.default" 'listen = ' "listen = 127.0.0.1:$php_port"
modify_config_file "$install_dir/etc/php-fpm.conf.default" 'listen.allowed_clients =' 'listen.allowed_clients = 127.0.0.1'
modify_config_file "$install_dir/etc/php-fpm.conf.default" 'error_log =' "error_log = $install_dir/php-fpm.error.log"
modify_config_file "$install_dir/etc/php-fpm.conf.default" 'access.log = ' "access.log = $install_dir/php-fpm.access.log"
cp -f "$install_dir/etc/php-fpm.conf.default" "$install_dir/php-fpm.conf"

cp -f 'sapi/fpm/init.d.php-fpm' "$install_dir/etc/init.d.php-fpm"
modify_config_file "$install_dir/etc/init.d.php-fpm" 'php_fpm_CONF=' "php_fpm_CONF=$install_dir/php-fpm.conf"
modify_config_file "$install_dir/etc/init.d.php-fpm" 'php_fpm_PID=' "php_fpm_PID=$install_dir/$service_name.pid"
cp -f "$install_dir/etc/init.d.php-fpm" "/etc/init.d/$service_name"
chmod +x "/etc/init.d/$service_name"
chkconfig "$service_name" on

service "$service_name" start

"$install_dir/sbin/php-fpm" -v
"$install_dir/bin/php" -v
"$install_dir/bin/php" -m

ps -aux | grep "php"

show_listen