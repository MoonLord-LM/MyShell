#!/bin/bash

# V2Ray
# 开源地址：https://github.com/v2fly/v2ray-core
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash



# 参数设置
v2ray_uuid=$(cat '/proc/sys/kernel/random/uuid')
v2ray_port=10010
v2ray_path='/ws/10010'

function v2ray_config_json(){
    cat <<EOF
{
  "inbounds": [
    {
      "port": ${v2ray_port},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${v2ray_uuid}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${v2ray_path}"
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



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
bash <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh' )
if [ $? -ne 0 ]; then
    log_error 'v2ray install failed, quit now'
    exit 1
fi

check_command_exist 'v2ray'
if [ $? -ne 0 ]; then
    log_error 'v2ray install failed, quit now'
    exit 1
fi

v2ray version
if [ $? -ne 0 ]; then
    log_error 'v2ray install failed, quit now'
    exit 1
fi



# 写入配置（uuid 随机生成，并在日志中展示）：
v2ray_config_json > '/usr/local/etc/v2ray/config.json'
if [ $? -ne 0 ]; then
    log_error 'v2ray write config failed, quit now'
    exit 1
fi

log_attention "v2ray port: ${v2ray_port}"
log_attention "v2ray path: ${v2ray_path}"
log_attention "v2ray uuid: ${v2ray_uuid}"
cat '/usr/local/etc/v2ray/config.json'



# 启动服务：
systemctl restart 'v2ray'
systemctl enable 'v2ray'
systemctl status --no-pager 'v2ray'

show_tcp_listening


