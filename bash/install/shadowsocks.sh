#!/bin/bash

# Shadowsocks
# 开源地址：https://github.com/shadowsocks/shadowsocks-rust
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks.sh' | bash



# 参数设置：
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
ExecStart=/usr/local/bin/ssserver -c "${ss_server_config_file}"
Restart=on-failure

[Install]
WantedBy=multi-user.target
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
tmp_file="/tmp/shadowsocks-rust_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.tar.gz"
ss_file_name_suffix="$(uname -m)-unknown-linux-gnu.tar.gz"

ss_download_url=$(
    wget -O- --timeout=60 --no-cache 'https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest' | \
    grep --color=never -o 'https://[^"]*' | \
    grep --color=never "$ss_file_name_suffix" | \
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

tar -xzf "$tmp_file" -C '/usr/local/bin' 'ssserver'
if [ $? -ne 0 ]; then
    log_error 'shadowsocks-rust extract failed, quit now'
    exit 1
fi
chmod +x '/usr/local/bin/ssserver'
rm -f "$tmp_file"

ss_service_file > '/etc/systemd/system/ssserver.service'
systemctl daemon-reload

mkdir -p '/usr/local/etc/ssserver'
backup_file "$ss_server_config_file"
ss_config_json > "$ss_server_config_file"
cat "$ss_server_config_file"

ss_server_ip=$(hostname -I | awk '{print $1}')
log_attention "shadowsocks server ip: ${ss_server_ip}"
log_attention "shadowsocks port: ${ss_server_port}"
log_attention "shadowsocks method: ${ss_method}"
log_attention "shadowsocks password: ${ss_password}"

ss_share_url='ss://'$(printf '%s' "${ss_method}:${ss_password}" | base64 -w 0 | tr '+' '-' | tr '/' '_' | tr -d '=')'@'${ss_server_ip}':'${ss_server_port}
log_attention "shadowsocks share url: ${ss_share_url}"



# 启动服务：
systemctl restart 'ssserver'
systemctl enable 'ssserver'
systemctl status --no-pager 'ssserver'

show_tcp_listening


