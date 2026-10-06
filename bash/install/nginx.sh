#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

# apt remove -y nginx

# Nginx
# https://github.com/nginx





# ———————————————————————— Config ————————————————————————
nginx_ssl_key='/etc/nginx/ssl/server-key.pem'
nginx_ssl_cert='/etc/nginx/ssl/server-cert.pem'

nginx_main_config_file='/etc/nginx/nginx.conf'
nginx_default_config_file='/etc/nginx/sites-available/default'
nginx_web_root='/var/www/html'

v2ray_server_config_file='/usr/local/etc/v2ray/config.json'

nginx_forward_server_and_port='frp:17500 prometheus:19090 grafana:13000 portainer:19443 cockpit:19190 openlist:17443'
nginx_forward_server_ip='127.0.0.1'

run_uid_gid='www-data:www-data'

function get_php_fpm_listen(){
    local php_fpm_listen=$(find '/run/php' -maxdepth 1 -name 'php*-fpm.sock' 2>'/dev/null' | sort | head -n 1)
    if [ "$php_fpm_listen" == '' ]; then
        log_info 'php-fpm not found, nginx config without php support'
        return 1
    fi
    log_important "php-fpm detected: fastcgi_pass unix:${php_fpm_listen}"
    echo "$php_fpm_listen"
}

function get_v2ray_ws_forward(){
    local v2ray_service=$(systemctl list-units --type=service --state=active --no-legend --no-pager 'v2ray.service' 2>'/dev/null' | awk '{print $1}' | head -n 1)
    if [ "$v2ray_service" == '' ]; then
        log_info 'v2ray not found, nginx config without v2ray ws forward'
        return 1
    fi
    if [ ! -f "$v2ray_server_config_file" ]; then
        log_info "v2ray config file not found: \"${v2ray_server_config_file}\", nginx config without v2ray ws forward"
        return 1
    fi
    local v2ray_forward=$(python3 -c '
import json, sys
inbound = json.load(open(sys.argv[1]))["inbounds"][0]
print(str(inbound["port"]) + ":" + inbound["streamSettings"]["wsSettings"]["path"])
' "$v2ray_server_config_file" 2>'/dev/null')
    if [ "$v2ray_forward" == '' ]; then
        log_info "v2ray port or ws path not found in \"${v2ray_server_config_file}\", nginx config without v2ray ws forward"
        return 1
    fi
    local v2ray_port="${v2ray_forward%%:*}"
    local v2ray_path="${v2ray_forward#*:}"
    log_important "v2ray detected: location ${v2ray_path} -> proxy_pass http://127.0.0.1:${v2ray_port}"
    echo "${v2ray_port}:${v2ray_path}"
}

function nginx_main_config(){
    cat <<EOF
user www-data;

worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 163840;

pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 10240;
    multi_accept on;
    reuseport on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    keepalive_timeout 300s;
    keepalive_requests 10000;

    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1800s;
    ssl_session_tickets on;

    access_log /var/log/nginx/access.log;

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
}

function nginx_server_config(){
    local php_fpm_listen=$(get_php_fpm_listen)
    local v2ray_forward=$(get_v2ray_ws_forward)
    local nginx_index='index.html index.htm index.nginx-debian.html'
    local nginx_not_found_files='/404.html'
    if [ "$php_fpm_listen" != '' ]; then
        nginx_index='index.php index.html'
        nginx_not_found_files='/404.php /404.html'
    fi
    cat <<EOF
map \$http_upgrade \$connection_upgrade { default upgrade; '' ''; }

server {
    listen 80 so_keepalive=15:15:3 default_server;
    listen [::]:80 so_keepalive=15:15:3 default_server;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl so_keepalive=15:15:3 default_server;
    listen [::]:443 ssl so_keepalive=15:15:3 default_server;

    ssl_certificate_key "${nginx_ssl_key}";
    ssl_certificate "${nginx_ssl_cert}";
    ssl_protocols TLSv1.2 TLSv1.3;
    gzip off;

    server_name _;

    root ${nginx_web_root};

    index ${nginx_index};

    error_page 404 =404 @not_found;

    location @not_found {
        try_files ${nginx_not_found_files} =404;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    location = /nginx_status {
        stub_status;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
    }
EOF
    if [ "$php_fpm_listen" != '' ]; then
        cat <<EOF

    location ~ \.php\$ {
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET,POST,OPTIONS,HEAD,PUT,DELETE" always;
        add_header Access-Control-Allow-Headers "Content-Type,X-Requested-With" always;
        add_header X-Content-Type-Options nosniff always;

        if (\$request_method = OPTIONS) {
            return 204;
        }

        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_fpm_listen};
    }
EOF
    fi
    if [ "$v2ray_forward" != '' ]; then
        local v2ray_port="${v2ray_forward%%:*}"
        local v2ray_path="${v2ray_forward#*:}"
        cat <<EOF

    location ${v2ray_path} {
        proxy_pass http://127.0.0.1:${v2ray_port};
        proxy_http_version 1.1;
        proxy_set_header Host \$http_host;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_redirect off;
    }
EOF
    fi
    cat <<EOF
}

EOF
    local forward=''
    for forward in $nginx_forward_server_and_port; do
        local forward_key="${forward%%:*}"
        local forward_port="${forward#*:}"
        cat <<EOF
upstream backend_${forward_key} {
    server ${nginx_forward_server_ip}:${forward_port};
    keepalive 100;
    keepalive_timeout 300s;
    keepalive_requests 10000;
}

server {
    listen 443 ssl so_keepalive=15:15:3;
    listen [::]:443 ssl so_keepalive=15:15:3;

    ssl_certificate_key "${nginx_ssl_key}";
    ssl_certificate "${nginx_ssl_cert}";
    ssl_protocols TLSv1.2 TLSv1.3;
    gzip off;

    server_name ~^[^.]*${forward_key}[^.]*\.[^.]+\.[^.]+;

    location / {
        proxy_pass https://backend_${forward_key};
        proxy_http_version 1.1;
        proxy_set_header Host \$http_host;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_ssl_name \$http_host;
        proxy_ssl_server_name on;
        proxy_ssl_session_reuse on;
        proxy_ssl_verify off;
        proxy_redirect off;
    }
}

EOF
    done
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
check_command_exist 'nginx'
if [ $? -eq 0 ]; then
    log_info 'nginx already installed, quit now'
    exit 0
fi

install_software 'nginx'
{
    if_error_then_exit 'nginx install failed, quit now'
}

nginx -v
{
    if_error_then_exit 'nginx version check failed, quit now'
}

generate_ssl_cert 'Nginx' "$nginx_ssl_key" "$nginx_ssl_cert"
{
    if_error_then_exit 'nginx ssl cert generate failed, quit now'
}

if [ "$(get_php_fpm_listen)" != '' ]; then
    if [ ! -f "${nginx_web_root}/index.php" ]; then
        update_file "${nginx_web_root}/index.php" '<?php phpinfo(); ?>' "$run_uid_gid"
        {
            if_error_then_exit 'nginx phpinfo index.php write failed, quit now'
        }
    fi
    rm -f "${nginx_web_root}/index.nginx-debian.html"
fi

update_file "$nginx_main_config_file" "$(nginx_main_config)"
{
    if_error_then_exit 'nginx main config write failed, quit now'
}
cat "$nginx_main_config_file"

update_file "$nginx_default_config_file" "$(nginx_server_config)"
{
    if_error_then_exit 'nginx default config write failed, quit now'
}
cat "$nginx_default_config_file"

nginx -t
{
    if_error_then_exit 'nginx config test failed, quit now'
}





# ———————————————————————— Start ————————————————————————
systemctl restart 'nginx'
systemctl enable 'nginx'
systemctl status --no-pager 'nginx'

show_tcp_listening
