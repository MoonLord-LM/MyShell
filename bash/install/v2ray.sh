#!/bin/bash

# V2Ray
# 开源地址：https://github.com/v2fly/v2ray-core
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash



# 参数设置：
function v2ray_config_json(){
    cat <<EOF
{
  "inbounds": [{
    "port": 10010,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "4c92f93c-2ca9-4c81-ad76-41b1043f8e98",
          "level": 1,
          "alterId": 64
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/ws/10010"
      }
    }
  }],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ]
}
EOF
}

function v2ray_nginx_config(){
    cat <<EOF
server {

    listen      80;
    listen [::]:80;

    listen      443 ssl;
    listen [::]:443 ssl;

    ssl_certificate     /etc/nginx/ssl/moonlord.cc.crt;
    ssl_certificate_key /etc/nginx/ssl/moonlord.cc.key;

    server_name _;

    root /var/www/html;
    index index.php index.html;

    location /ws/10010 {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10010;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location ~ \.php$ {
        include      snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

}
EOF
}



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
check_command_exist 'v2ray' || install_software 'v2ray'
v2ray_config_json > '/etc/v2ray/config.json'
v2ray -version
if [ $? -ne 0 ]; then
    log_error 'v2ray install failed, quit now'
    exit 1
fi

check_command_exist 'nginx'
if [ $? -eq 0 ]; then
    site_available_path='/etc/nginx/sites-available'
    site_enabled_path='/etc/nginx/sites-enabled'
    v2ray_nginx_config > "$site_available_path/v2ray.conf"
    rm -rf "$site_enabled_path/v2ray.conf"
    ln -s "$site_available_path/v2ray.conf" "$site_enabled_path/v2ray.conf"
    systemctl restart 'nginx'
fi



# 启动服务：
systemctl restart 'v2ray'
systemctl enable 'v2ray'
systemctl status --no-pager 'v2ray'

show_tcp_listening


