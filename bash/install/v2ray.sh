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



# 启动服务：
systemctl restart 'v2ray'
systemctl enable 'v2ray'
systemctl status --no-pager 'v2ray'

show_tcp_listening


