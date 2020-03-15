#!/bin/bash
source ./My.sh

# Shadowsocks 3.3.4 在线安装
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_3.3.4.sh



# 参数设置
ss_version='3.3.4'
ss_server_port='10002'
ss_server_password="Ecs1312357@SS"
ss_source_url='https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.3.4/shadowsocks-libev-3.3.4.tar.gz'
ss_source_md5='fb41e60db217b658a14fe3519cd78c62'



# 卸载清理
service_name="ssserver$ss_server_port.service"
source_name="shadowsocks-libev-$ss_version"
install_dir="/usr/local/shadowsocks/shadowsocks-$ss_version"

service_file="/usr/lib/systemd/system/$service_name"
if [ -f $service_file ]; then
    sudo systemctl stop "$service_name"
    sudo systemctl disable "$service_name"
    sudo systemctl daemon-reload
    sudo rm -rf '/etc/shadowsocks.json'
    sudo rm -rf '/var/run/shadowsocks.pid'
    sudo rm -rf '/var/log/shadowsocks.log'
    sudo rm -rf "$install_dir"
    sudo rm -rf "$service_file"
fi



# 开始安装
prepare_source "$ss_source_url" "$ss_source_md5"
install_require 'pcre-devel'
install_require 'c-ares-devel'
install_require 'libev-devel'
install_require 'libsodium-devel'
install_require 'mbedtls-devel'

set_user_dir 'root' "$install_dir"
set_user_file 'root' "$install_dir/shadowsocks.json"
set_user_file 'root' "$install_dir/ssserver.log"
set_user_file 'root' "$install_dir/$service_name"

cd "$source_name"
./configure \
 --prefix="$install_dir" \
 --exec-prefix="$install_dir" \
 --sysconfdir="$install_dir" \
 --localstatedir="$install_dir" \
 --runstatedir="$install_dir" \
 --disable-documentation \
 2>&1 | tee 'configure.log'
make -j `grep 'processor' '/proc/cpuinfo' | wc -l` 2>&1 | tee 'make.log'
make install

# https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File
# https://github.com/shadowsocks/shadowsocks/wiki/Configure-Multiple-Users
cd "$install_dir"
cat << EOF > "shadowsocks.json"
{
    "server": "::",
    "server_port": $ss_server_port,
    "password": "$ss_server_password",
    "timeout": 300,
    "method": "aes-256-gcm",
    "fast_open": true,
    "workers": `grep 'processor' '/proc/cpuinfo' | wc -l`,
    "user": "nobody",
    "reuse_port": true,
    "mode": "tcp_and_udp"
}
EOF

cd "$install_dir"
cat << EOF > "$service_name"
[Unit]
Description=Shadowsocks Server
After=syslog.target
After=network.target
After=remote-fs.target
After=nss-lookup.target

[Install]
WantedBy=multi-user.target

[Service]
User=root
Group=root

Type=forking
PIDFile=$install_dir/ssserver.pid

ExecStartPre=$install_dir/bin/ss-server -h | head -n 5
ExecStart=$install_dir/bin/ss-server -c "$install_dir/shadowsocks.json" -f "$install_dir/ssserver.pid" >"$install_dir/ssserver.log" 2>&1

LimitNOFILE=65535
Restart=on-failure
PrivateTmp=true
EOF

cp -f "$install_dir/$service_name" "$service_file"
systemctl enable "$service_name"
systemctl daemon-reload
systemctl start "$service_name"
systemctl status -l "$service_name"

"$install_dir/bin/ss-server" -h | head -n 5

show_disk_usage "$install_dir"
show_listen
