#!/bin/bash
source ./My.sh

# Nginx 1.15.2 在线安装
# sudo chmod -R 777 ./ && sudo sh ./nginx_1.15.2.sh
# sudo chmod -R 777 ./ && sudo sh ./nginx_1.15.2.sh --delete_exist


# 参数设置
nginx_version='1.15.2'
nginx_num='1152'
nginx_source_url='http://nginx.org/download/nginx-1.15.2.tar.gz'


# 开始安装
service_name="nginx$nginx_num"
source_dir="nginx-$nginx_version"
install_dir="/usr/local/nginx/nginx-$nginx_version"

if [ "$1" == "--delete_exist" ];then
    sudo systemctl stop "${service_name}.service"
    sudo systemctl disable "${service_name}.service"
    sudo rm -rf "/usr/lib/systemd/system/${service_name}.service"
    sudo rm -rf "$install_dir"
    sudo systemctl daemon-reload
fi

if [ -d "$install_dir" ];then
    die '[ Error ] install_dir exists!'
fi

prepare_source "$nginx_source_url"
install_require 'openssl-devel'
install_require 'pcre-devel'
install_require 'zlib-devel'

add_user_group 'nginx' 'Nginx Server' '/usr/local/nginx'
set_user_dir 'nginx' "$install_dir"
set_user_dir 'nginx' "$install_dir/etc"
set_user_file 'nginx' "$install_dir/nginx.conf"
set_user_file 'nginx' "$install_dir/nginx_error.log"
set_user_file 'nginx' "$install_dir/nginx_access.log"
set_user_file 'nginx' "$install_dir/$service_name.lock"

# http://nginx.org/en/docs/configure.html
cd "$source_dir"
./configure \
 --prefix="$install_dir" \
 --conf-path="$install_dir/nginx.conf" \
 --error-log-path="$install_dir/nginx_error.log" \
 --http-log-path="$install_dir/nginx_access.log" \
 --pid-path="$install_dir/$service_name.pid" \
 --lock-path="$install_dir/$service_name.lock" \
 --user='nginx' \
 --group='nginx' \
 --with-http_flv_module \
 --with-http_mp4_module \
 --with-http_realip_module \
 --with-http_ssl_module \
 --with-http_stub_status_module \
 --with-stream \
 --build="compiled at `cat '/etc/redhat-release'`" \
 2>&1 | tee 'configure.log'
make -j `grep processor '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

# https://www.nginx.com/resources/wiki/start/topics/examples/systemd/
cd "$install_dir/etc"
cat <<EOF > "${service_name}.service"
[Unit]
Description=Nginx Server
After=syslog.target
After=network.target
After=remote-fs.target
After=nss-lookup.target

[Install]
WantedBy=multi-user.target

[Service]
User=root
Group=root

Type=forking
PIDFile=$install_dir/$service_name.pid

ExecStartPre="$install_dir/sbin/nginx" -t -c "$install_dir/nginx.conf"
ExecStart="$install_dir/sbin/nginx" -c "$install_dir/nginx.conf"
ExecReload="$install_dir/sbin/nginx" -s reload
ExecStop="$install_dir/sbin/nginx" -s quit

LimitNOFILE=65536
Restart=on-failure
PrivateTmp=true
EOF

cp -f "$install_dir/nginx.conf.default" "$install_dir/nginx.conf"
cp -f $install_dir/*.default "$install_dir/etc/"
rm -rf $install_dir/*.default
cp -f "$install_dir/etc/${service_name}.service" "/usr/lib/systemd/system/${service_name}.service"

systemctl enable "${service_name}.service"
systemctl daemon-reload
systemctl start "${service_name}.service"
systemctl status -l "${service_name}.service"

show_listen