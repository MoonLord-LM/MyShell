#!/bin/bash
source ./My.sh

# Nginx 1.15.2 在线安装
# sudo chmod -R 777 ./ && sudo sh ./nginx_1.15.2.sh --install
# sudo chmod -R 777 ./ && sudo sh ./nginx_1.15.2.sh --reinstall
# sudo chmod -R 777 ./ && sudo sh ./nginx_1.15.2.sh --clean_cache


# 参数设置
nginx_version='1.15.2'
nginx_port='1152'
nginx_source_url='http://nginx.org/download/nginx-1.15.2.tar.gz'



# 选项解析
service_name="nginx$nginx_port"
source_name="nginx-$nginx_version"
install_dir="/usr/local/nginx/nginx-$nginx_version"

if [ "$1" == "--reinstall" ]; then
    sudo systemctl stop "${service_name}.service"
    sudo systemctl disable "${service_name}.service"
    sudo rm -rf "/usr/lib/systemd/system/${service_name}.service"
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
prepare_source "$nginx_source_url"
install_require 'openssl-devel'
install_require 'pcre-devel'
install_require 'zlib-devel'

add_user_group 'nginx' 'Nginx Server' '/usr/local/nginx'
set_user_dir 'nginx' "$install_dir"
set_user_dir 'nginx' "$install_dir/etc"
set_user_dir 'nginx' "$install_dir/vhost"
set_user_file 'nginx' "$install_dir/nginx.conf"
set_user_file 'nginx' "$install_dir/nginx_error.log"
set_user_file 'nginx' "$install_dir/nginx_access.log"
set_user_file 'nginx' "$install_dir/$service_name.lock"

# http://nginx.org/en/docs/configure.html
cd "$source_name"
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
make -j `grep 'processor' '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

# https://www.nginx.com/resources/wiki/start/topics/examples/systemd/
cd "$install_dir/etc"
cat << EOF > "${service_name}.service"
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

LimitNOFILE=65535
Restart=on-failure
PrivateTmp=true
EOF

# http://nginx.org/en/docs/beginners_guide.html
cd "$install_dir"
cat << EOF > "nginx.conf"
user  nginx nginx;
worker_processes  `grep 'processor' '/proc/cpuinfo' | wc -l`;
worker_rlimit_nofile  65535;

events {
    use  epoll;
    worker_connections  65535;
}

http {
    include  mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    sendfile  on;
    tcp_nodelay  on;
    server_tokens on;
    keepalive_timeout  120;

    gzip  on;
    gzip_comp_level  1;
    gzip_min_length  1k;
    gzip_types  text/plain text/css text/javascript text/xml;

    open_file_cache  max=65535 inactive=60s;
    open_file_cache_min_uses  1;
    open_file_cache_valid 30s;

    include  vhost/*.conf;

    server {
        listen       [::]:$nginx_port ipv6only=off;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page  404 500 502 503 504 /50x.html;
    }
}
EOF

cp -f $install_dir/*.default "$install_dir/etc/"
rm -rf $install_dir/*.default
cp -f "$install_dir/etc/${service_name}.service" "/usr/lib/systemd/system/${service_name}.service"

wget 'http://nginx.org/favicon.ico'  -O "$install_dir/html/favicon.ico"

systemctl enable "${service_name}.service"
systemctl daemon-reload
systemctl start "${service_name}.service"
systemctl status -l "${service_name}.service"

"$install_dir/sbin/nginx" -V

show_listen