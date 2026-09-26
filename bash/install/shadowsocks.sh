#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks.sh' | bash

# Shadowsocks
# https://github.com/shadowsocks/shadowsocks-rust





# ———————————————————————— Config ————————————————————————
ss_server_location='/usr/local/bin/ssserver'
ss_server_config_file='/usr/local/etc/ssserver/config.json'
ss_server_port=10000
ss_password=$(head -c 32 '/dev/urandom' | base64 -w 0)
ss_method='2022-blake3-aes-256-gcm'

function ss_config_json(){
    cat <<EOF
{
    "server": "::",
    "server_port": ${ss_server_port},
    "password": "${ss_password}",
    "method": "${ss_method}"
}
EOF
}

function ss_service_file(){
    cat <<EOF
[Unit]
Description=shadowsocks-rust ssserver
After=network-online.target

[Service]
ExecStart="${ss_server_location}" -c "${ss_server_config_file}"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist 'ssserver'
if [ $? -eq 0 ]; then
    log_info 'shadowsocks already installed, quit now'
    exit 0
fi

tmp_file="/tmp/shadowsocks-rust_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.tar"
ss_file_name_match="$(uname -m)-unknown-linux-musl"

ss_download_url=$(
    wget -O- --timeout=120 --no-cache 'https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest' | \
    grep --color=never -o 'https://[^"]*' | \
    grep --color=never "$ss_file_name_match.tar.\(xz\|gz\)\$" | \
    head -n 1
)
if [ "$ss_download_url" == '' ]; then
    log_error 'shadowsocks-rust download url not found, quit now'
    exit 1
fi

wget -O "$tmp_file" --timeout=120 --no-cache "$ss_download_url"
if [ $? -ne 0 ]; then
    log_error 'shadowsocks-rust download failed, quit now'
    exit 1
fi

mkdir -p $(dirname "$ss_server_location")
tar -xf "$tmp_file" -C $(dirname "$ss_server_location") 'ssserver'
if [ $? -ne 0 ]; then
    log_error 'shadowsocks-rust extract failed, quit now'
    exit 1
fi

chmod +x "$ss_server_location"
rm -f "$tmp_file"

ss_service_file > '/etc/systemd/system/ssserver.service'
systemctl daemon-reload

backup_file "$ss_server_config_file"
mkdir -p $(dirname "$ss_server_config_file")
ss_config_json > "$ss_server_config_file"
if [ $? -ne 0 ]; then
    log_error 'ssserver write config failed, quit now'
    exit 1
fi
cat "$ss_server_config_file"

ss_server_ip=$(hostname -I | awk '{print $1}')
log_attention "shadowsocks server ip: ${ss_server_ip}"
log_attention "shadowsocks port: ${ss_server_port}"
log_attention "shadowsocks method: ${ss_method}"
log_attention "shadowsocks password: ${ss_password}"

ss_share_url='ss://'$(printf '%s' "${ss_method}:${ss_password}" | base64 -w 0 | tr '+' '-' | tr '/' '_' | tr -d '=')'@'${ss_server_ip}':'${ss_server_port}'#'${ss_server_ip}
log_attention "shadowsocks share url: ${ss_share_url}"





# ———————————————————————— Start ————————————————————————
systemctl restart 'ssserver'
systemctl enable 'ssserver'
systemctl status --no-pager 'ssserver'

show_tcp_listening
