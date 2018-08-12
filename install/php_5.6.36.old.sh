#!/bin/bash
source ./My.sh

# PHP 5.6.36 在线安装

php_source_url="http://cn2.php.net/distributions/php-5.6.36.tar.gz"
php_source_file="php-5.6.36.tar.gz"
php_source_folder="php-5.6.36"

freetype_source_url="https://jaist.dl.sourceforge.net/project/freetype/freetype2/2.9.1/freetype-2.9.1.tar.gz"
freetype_source_file="freetype-2.9.1.tar.gz"
freetype_source_folder="freetype-2.9.1"

php_install_path="/usr/local/php-5.6.36"
php_bin_path="/usr/local/php-5.6.36/bin/php"
php_ini_path="/usr/local/php-5.6.36/etc/php.ini"
php_fpm_conf_path="/usr/local/php-5.6.36/etc/php-fpm.conf"

php_error_log_file="/var/log/php_5.6.36_error.log"
php_fpm_error_log_file="/var/log/php_5.6.36_fpm_error.log"

echo "PHP 源码下载……"
if [ ! -f $php_source_file ]; then
    echo "PHP 源码文件不存在，开始下载……"
    wget -O $php_source_file $php_source_url
else
    echo "PHP 源码文件已存在，重新下载……"
    rm -rf $php_source_file
    wget -O $php_source_file $php_source_url
fi

if [ ! -f $php_source_file ]; then
    die "【Error】PHP 源码文件文件下载失败……"
fi

echo "PHP 源码解压……"
tar -zxvf $php_source_file
# z:zip x:extract v:verbose f:filename
cd $php_source_folder

echo "PHP 安装准备……"
function check_require(){
    if [ "$1" != "" ]; then
        tmp=`yum list installed | grep "$1"`
        if [ "$tmp" = "" ]; then
            yum install $1 -y
            if [ $? -ne 0 ]; then
                echo "trying to install: $1……"
                if [ "$1" == "freetype" ]; then
                    wget $freetype_source_url
                    tar -zxvf $freetype_source_file
                    cd $freetype_source_folder
                    ./configure
                    make install
                    cd ..
                fi
            fi
        fi
    fi
}
check_require "freetype"
check_require "libcurl-devel"
check_require "libmcrypt-devel"
check_require "libpng-devel"
check_require "libxml2-devel"
check_require "libxslt-devel"
check_require "openssl-devel"
check_require "postgresql-devel"

echo "PHP 安装配置……"
./configure --prefix=$php_install_path \
 --with-curl \
 --with-freetype \
 --with-gd \
 --with-gettext \
 --with-iconv-dir \
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
 --enable-bcmath \
 --enable-fpm \
 --enable-ftp \
 --enable-gd-native-ttf \
 --enable-libxml \
 --enable-inline-optimization \
 --enable-mbregex \
 --enable-mbstring \
 --enable-memcache \
 --enable-opcache \
 --enable-pcntl \
 --enable-shmop \
 --enable-soap \
 --enable-sockets \
 --enable-sysvsem \
 --enable-xml \
 --enable-zip

echo "PHP 开始安装……"
make install

echo "PHP 开始配置……"
cp "php.ini-production" $php_ini_path

cp "$php_fpm_conf_path.default" $php_fpm_conf_path
cp "sapi/fpm/init.d.php-fpm" "/etc/init.d/php-fpm"
chmod 700 "/etc/init.d/php-fpm" || die "【Error】chmod failed!"
chkconfig php-fpm on

groupadd www
useradd -g www www -s /sbin/nologin

tmp=`grep "log_errors_max_len = 1024" $php_ini_path`
if [ "$tmp" != "" ]; then
    sed -i "s#^\s*log_errors_max_len\s*=\s*1024#log_errors_max_len = 0#g" $php_ini_path
fi
grep "log_errors_max_len = " $php_ini_path

touch $php_error_log_file || die "【Error】touch failed!"
chmod 640 $php_error_log_file || die "【Error】chmod failed!"
chown www.www $php_error_log_file || die "【Error】chown failed!"

tmp=`grep ";error_log = php_errors.log" $php_ini_path`
if [ "$tmp" != "" ]; then
    sed -i "s#^\s*;error_log\s*=\s*php_errors.log#error_log = $php_error_log_file#g" $php_ini_path
fi
grep "error_log = " $php_ini_path

touch $php_fpm_error_log_file || die "【Error】touch failed!"
chmod 640 $php_fpm_error_log_file || die "【Error】chmod failed!"
chown www.www $php_fpm_error_log_file || die "【Error】chown failed!"

tmp=`grep ";error_log = log/php-fpm.log" $php_fpm_conf_path`
if [ "$tmp" != "" ]; then
    sed -i "s#^\s*;error_log\s*=\s*log/php-fpm.log#error_log = $php_fpm_error_log_file#g" $php_fpm_conf_path
fi
grep "error_log = " $php_fpm_conf_path

tmp=`grep "user = nobody" $php_fpm_conf_path`
if [ "$tmp" != "" ]; then
    sed -i "s#^\s*user\s*=\s*nobody#user = www#g" $php_fpm_conf_path
fi
grep "user = " $php_fpm_conf_path

tmp=`grep "group = nobody" $php_fpm_conf_path`
if [ "$tmp" != "" ]; then
    sed -i "s#^\s*group\s*=\s*nobody#group = www#g" $php_fpm_conf_path
fi
grep "group = " $php_fpm_conf_path

echo "PHP 重启服务……"
service php-fpm restart

echo "PHP 显示模块……"
$php_bin_path -m

echo "PHP 显示版本……"
$php_bin_path -v

echo "PHP 显示进程……"
ps -aux | grep "php-fpm"

echo "PHP 显示端口……"
netstat -lnp