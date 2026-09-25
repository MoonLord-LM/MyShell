#!/bin/bash

# V2Ray
# 开源地址：https://github.com/v2fly/v2ray-core
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash



# 参数设置：
v2ray_server_port=10010
v2ray_client_id=$(cat '/proc/sys/kernel/random/uuid')
v2ray_ws_path='/ws/'$(cat '/proc/sys/kernel/random/uuid')

function v2ray_server_config(){
    cat <<EOF
{
  "inbounds": [
    {
      "port": ${v2ray_server_port},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${v2ray_client_id}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${v2ray_ws_path}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
}

function v2ray_client_config(){
    cat <<EOF
{
  "v": "2",
  "ps": "${v2ray_server_ip}",
  "add": "${v2ray_server_ip}",
  "port": "${v2ray_server_port}",
  "id": "${v2ray_client_id}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${v2ray_server_ip}",
  "path": "${v2ray_ws_path}",
  "tls": "",
  "sni": "",
  "alpn": "",
  "fp": ""
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
bash <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh' )

v2ray version
if [ $? -ne 0 ]; then
    log_error 'v2ray install failed, quit now'
    exit 1
fi

backup_file '/usr/local/etc/v2ray/config.json'
v2ray_server_config > '/usr/local/etc/v2ray/config.json'
if [ $? -ne 0 ]; then
    log_error 'v2ray write config failed, quit now'
    exit 1
fi
cat '/usr/local/etc/v2ray/config.json'

v2ray_server_ip=$(hostname -I | awk '{print $1}')
log_attention "v2ray server ip: ${v2ray_server_ip}"
log_attention "v2ray port: ${v2ray_server_port}"
log_attention "v2ray client id: ${v2ray_client_id}"
log_attention "v2ray ws path: ${v2ray_ws_path}"

v2ray_vmess_url='vmess://'$(v2ray_client_config | base64 -w 0)
log_attention "v2ray share url: ${v2ray_vmess_url}"



# 启动服务：
systemctl restart 'v2ray'
systemctl enable 'v2ray'
systemctl status --no-pager 'v2ray'

show_tcp_listening


