#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks.sh' | bash

# export SS_PASSWORD='<password>'
# systemctl disable --now 'ssserver' && rm -f '/usr/local/bin/ssserver' "$ss_server_service_file" && rm -rf '/usr/local/etc/ssserver/'

# Shadowsocks
# https://github.com/shadowsocks/shadowsocks-rust





# ———————————————————————— Config ————————————————————————
ss_server_api_release_url='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'

ss_server_location='/usr/local/bin/ssserver'
ss_server_config_file='/usr/local/etc/ssserver/config.json'
ss_server_service_file='/etc/systemd/system/ssserver.service'

ss_server_port=10000
ss_password="${SS_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"
ss_password_escaped=$(printf '%s' "$ss_password" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
ss_method='2022-blake3-aes-256-gcm'

run_uid_gid='root:root'

function ss_config_json(){
    cat <<EOF
{
    "server": "::",
    "server_port": ${ss_server_port},
    "password": "${ss_password_escaped}",
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
check_command_exist 'ssserver'
if [ $? -eq 0 ]; then
    log_info 'shadowsocks already installed, quit now'
    exit 0
fi

log_warn 'if $SS_PASSWORD is not set, a random password will be generated:'
log_warn "export SS_PASSWORD='<password>'"

tmp_file="/tmp/shadowsocks-rust_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.tar"
ss_file_name_match="$(uname -m)-unknown-linux-musl"

ss_download_url=$(
    wget -O- --timeout=120 --no-cache "$ss_server_api_release_url" | \
    grep --color=never -o 'https://[^"]*' | \
    grep --color=never "$ss_file_name_match.tar.\(xz\|gz\)\$" | \
    head -n 1
)
if [ "$ss_download_url" == '' ]; then
    log_error 'shadowsocks-rust download url not found, quit now'
    exit 1
fi

wget -O "$tmp_file" --timeout=120 --no-cache "$ss_download_url"
{
    if_error_then_exit 'shadowsocks-rust download failed, quit now'
}

mkdir -p "$(dirname "$ss_server_location")"
tar -xf "$tmp_file" -C "$(dirname "$ss_server_location")" 'ssserver'
{
    if_error_then_exit 'shadowsocks-rust extract failed, quit now'
}

chmod +x "$ss_server_location"
rm -f "$tmp_file"

update_file "$ss_server_service_file" "$(ss_service_file)"
{
    if_error_then_exit 'ssserver service file write failed, quit now'
}
systemctl daemon-reload

update_file "$ss_server_config_file" "$(ss_config_json)" "$run_uid_gid" '600'
{
    if_error_then_exit 'ssserver write config failed, quit now'
}
cat "$ss_server_config_file"

ss_server_ip=$(get_system_ip)
log_attention "shadowsocks server ip: ${ss_server_ip}"
log_attention "shadowsocks port: ${ss_server_port}"
log_attention "shadowsocks method: ${ss_method}"
log_important "shadowsocks password: ${ss_password}"

ss_share_url='ss://'$(printf '%s' "${ss_method}:${ss_password}" | base64 -w 0 | tr '+' '-' | tr '/' '_' | tr -d '=')'@'${ss_server_ip}':'${ss_server_port}'#'${ss_server_ip}
log_important "shadowsocks share url: ${ss_share_url}"





# ———————————————————————— Start ————————————————————————
systemctl restart 'ssserver'
systemctl enable 'ssserver'
systemctl status --no-pager 'ssserver'

show_tcp_listening
