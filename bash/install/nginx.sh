#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

# apt remove -y nginx

# Nginx
# https://github.com/nginx





# ———————————————————————— Config ————————————————————————
nginx_ssl_key='/etc/nginx/ssl/server-key.pem'
nginx_ssl_cert='/etc/nginx/ssl/server-cert.pem'

nginx_default_config_file='/etc/nginx/sites-available/default'
nginx_web_root='/var/www/html'

v2ray_server_config_file='/usr/local/etc/v2ray/config.json'

run_uid_gid='www-data:www-data'

function get_php_fpm_listen(){
    local php_fpm_listen=$(find '/run/php' -maxdepth 1 -name 'php*-fpm.sock' 2> '/dev/null' | sort | head -n 1)
    if [ "$php_fpm_listen" == '' ]; then
        log_info 'php-fpm not found, nginx config without php support'
        return 1
    fi
    log_attention "php-fpm detected: fastcgi_pass unix:${php_fpm_listen}"
    echo "$php_fpm_listen"
}

function get_v2ray_ws_forward(){
    local v2ray_service=$(systemctl list-units --type=service --state=active --no-legend --no-pager 'v2ray.service' 2> '/dev/null' | awk '{print $1}' | head -n 1)
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
' "$v2ray_server_config_file" 2> '/dev/null')
    if [ "$v2ray_forward" == '' ]; then
        log_info "v2ray port or ws path not found in \"${v2ray_server_config_file}\", nginx config without v2ray ws forward"
        return 1
    fi
    local v2ray_port="${v2ray_forward%%:*}"
    local v2ray_path="${v2ray_forward#*:}"
    log_attention "v2ray detected: location ${v2ray_path} -> proxy_pass http://127.0.0.1:${v2ray_port}"
    echo "${v2ray_port}:${v2ray_path}"
}

function nginx_server_config(){
    local php_fpm_listen=$(get_php_fpm_listen)
    local v2ray_forward=$(get_v2ray_ws_forward)
    local nginx_index='index.html index.htm index.nginx-debian.html'
    if [ "$php_fpm_listen" != '' ]; then
        nginx_index='index.php index.html index.htm'
    fi
    cat <<EOF
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;

	ssl_certificate_key "${nginx_ssl_key}";
	ssl_certificate "${nginx_ssl_cert}";
	ssl_protocols TLSv1.2 TLSv1.3;
	gzip off;

	root ${nginx_web_root};

	index ${nginx_index};

	server_name _;

	location / {
		try_files \$uri \$uri/ =404;
	}
EOF
    if [ "$php_fpm_listen" != '' ]; then
        cat <<EOF

	location ~ \.php\$ {
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
		proxy_set_header Connection 'upgrade';
		proxy_set_header Upgrade \$http_upgrade;
		proxy_redirect off;
	}
EOF
    fi
    cat <<EOF
}
EOF
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi
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
