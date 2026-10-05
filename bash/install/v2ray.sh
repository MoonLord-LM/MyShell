#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/v2ray.sh' | bash

# export V2RAY_CLIENT_ID='<uuid>'
# export V2RAY_WS_PATH='<path>'
# bash <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh' ) --remove && rm -rf '/usr/local/etc/v2ray/'

# V2Ray
# https://github.com/v2fly/v2ray-core





# ———————————————————————— Config ————————————————————————
v2ray_server_config_file='/usr/local/etc/v2ray/config.json'
v2ray_server_port=10010

v2ray_client_id="${V2RAY_CLIENT_ID:-$(cat '/proc/sys/kernel/random/uuid')}"
v2ray_client_id_escaped=$(printf '%s' "$v2ray_client_id" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
v2ray_ws_path="${V2RAY_WS_PATH:-/ws/$(cat '/proc/sys/kernel/random/uuid')}"
v2ray_ws_path_escaped=$(printf '%s' "$v2ray_ws_path" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

run_uid_gid='65534:65534'

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
            "id": "${v2ray_client_id_escaped}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${v2ray_ws_path_escaped}"
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
  "id": "${v2ray_client_id_escaped}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${v2ray_server_ip}",
  "path": "${v2ray_ws_path_escaped}",
  "tls": "",
  "sni": "",
  "alpn": "",
  "fp": ""
}
EOF
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
check_command_exist 'v2ray'
if [ $? -eq 0 ]; then
    log_info 'v2ray already installed, quit now'
    exit 0
fi

log_warn 'if $V2RAY_CLIENT_ID is not set, a random client id will be generated:'
log_warn "export V2RAY_CLIENT_ID='<uuid>'"

log_warn 'if $V2RAY_WS_PATH is not set, a random ws path will be generated:'
log_warn "export V2RAY_WS_PATH='<path>'"

tmp_file="/tmp/v2ray-install-release_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.sh"
wget -O "$tmp_file" --timeout=10 --no-cache 'https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh'
{
    if_error_then_exit 'v2ray installer download failed, quit now'
}

bash "$tmp_file"
{
    if_error_then_exit 'v2ray install failed, quit now'
}
rm -f "$tmp_file"

v2ray version
{
    if_error_then_exit 'v2ray install failed, quit now'
}

update_file "$v2ray_server_config_file" "$(v2ray_server_config)" "$run_uid_gid" '600'
{
    if_error_then_exit 'v2ray write config failed, quit now'
}
cat "$v2ray_server_config_file"

v2ray_server_ip=$(get_system_ip)
log_attention "v2ray server ip: ${v2ray_server_ip}"
log_attention "v2ray port: ${v2ray_server_port}"
log_attention "v2ray client id: ${v2ray_client_id}"
log_attention "v2ray ws path: ${v2ray_ws_path}"

v2ray_share_url='vmess://'$(v2ray_client_config | base64 -w 0)
log_attention "v2ray share url: ${v2ray_share_url}"





# ———————————————————————— Start ————————————————————————
systemctl restart 'v2ray'
systemctl enable 'v2ray'
systemctl status --no-pager 'v2ray'

show_tcp_listening
