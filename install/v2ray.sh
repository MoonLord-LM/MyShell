#!/bin/bash
source ./My.sh

# V2Ray 在线安装
# sudo chmod -R 777 ./ && sudo sh ./v2ray.sh



# 参数设置
v2ray_server_port='10004'
v2ray_client_user_id="2edb07fc-ad78-4c82-9300-3c2cd13ed375"



# 开始安装
bash <(curl -L -s https://install.direct/go.sh)

v2ray_config_json=`find / -type f -name 'config.json' 2> '/dev/null' | grep '/etc/v2ray'`
if [ "$v2ray_config_json" == "" ]; then
    die '[ Error ] v2ray_config_json can not be found!'
    exit 1
fi
modify_config_file "$v2ray_config_json" \
 "    \"port\": " \
 "    \"port\": $v2ray_server_port,"
modify_config_file "$v2ray_config_json" \
 "          \"id\": " \
 "          \"id\": \"$v2ray_client_user_id\","
cat "$v2ray_config_json"

systemctl restart v2ray

sleep "3s"
show_listen
