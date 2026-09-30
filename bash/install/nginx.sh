#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/nginx.sh' | bash

# apt remove -y nginx

# Nginx
# https://github.com/nginx





# ———————————————————————— Config ————————————————————————
nginx_ssl_key='/etc/nginx/ssl/server-key.pem'
nginx_ssl_cert='/etc/nginx/ssl/server-cert.pem'

nginx_default_config_file='/etc/nginx/sites-available/default'

run_uid_gid='www-data:www-data'

function nginx_ssl_config(){
    cat <<EOF
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;

	ssl_certificate_key "${nginx_ssl_key}";
	ssl_certificate "${nginx_ssl_cert}";

	root /var/www/html;

	index index.html index.htm index.nginx-debian.html;

	server_name _;

	location / {
		try_files \$uri \$uri/ =404;
	}
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

update_file "$nginx_default_config_file" "$(nginx_ssl_config)"
{
    if_error_then_exit 'nginx default config write failed, quit now'
}
cat "$nginx_default_config_file"





# ———————————————————————— Start ————————————————————————
systemctl restart 'nginx'
systemctl enable 'nginx'
systemctl status --no-pager 'nginx'

show_tcp_listening
