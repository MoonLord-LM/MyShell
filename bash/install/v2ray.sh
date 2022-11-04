#!/bin/bash

# V2Ray
# 开源地址：https://github.com/v2fly/v2ray-core
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash



# 参数设置：
conf_resource='https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/nginx'

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
    wget -O "$site_available_path/v2ray.conf" --timeout=10 --no-cache "$conf_resource/v2ray.conf"
    if [ $? -ne 0 ]; then
        log_error "file create failed: \"$site_available_path/v2ray.conf\", quit now"
        exit 1
    fi

    rm -rf "$site_enabled_path/v2ray.conf"
    ln -s "$site_available_path/v2ray.conf" "$site_enabled_path/v2ray.conf"
    systemctl restart 'nginx'
    if [ $? -ne 0 ]; then
        systemctl status nginx.service
        log_error 'v2ray nginx config failed, quit now'
        exit 1
    fi
fi



# 启动服务：
systemctl restart 'v2ray'
systemctl enable 'v2ray'
systemctl status --no-pager 'v2ray'

show_tcp_listening


