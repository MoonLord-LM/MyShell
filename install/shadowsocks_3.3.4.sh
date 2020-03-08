#!/bin/bash
source ./My.sh

# Shadowsocks 3.3.4 在线安装
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_3.3.4.sh --install
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_3.3.4.sh --reinstall
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_3.3.4.sh --clean_cache


# 参数设置
ss_version='3.3.4'
ss_server_port='10002'
ss_server_password="Ecs1312357@SS"
ss_source_url='https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.3.4/shadowsocks-libev-3.3.4.tar.gz'



# 选项解析
service_name="ssserver$ss_server_port"
source_name="shadowsocks-libev-$ss_version"
install_dir="/usr/local/shadowsocks/shadowsocks-$ss_version"

if [ "$1" == "--install" ]; then
    if [ -d "$install_dir" ]; then
        die '[ Error ] install_dir exists!'
        exit 1
    fi
elif [ "$1" == "--reinstall" ]; then
    sudo rm -rf "./$source_name"
    sudo rm -rf "./$source_name.tar.gz"
    sudo systemctl stop "${service_name}.service"
    sudo systemctl disable "${service_name}.service"
    sudo rm -rf "/usr/lib/systemd/system/${service_name}.service"
    sudo rm -rf "$install_dir"
    sudo systemctl daemon-reload
else
    echo && \
    info 'options:' && \
    echo && \
    info "    --install      install $source_name" && \
    info "                   default install dir: $install_dir" && \
    info '                   if already installed, do nothing' && \
    echo && \
    info "    --reinstall    reinstall $source_name" && \
    info "                   default install dir: $install_dir" && \
    info '                   delete the existed, and redo installation' && \
    echo && \
    info '    --clean_cache  delete cached files' && \
    info '                   use this to save disk space' && \
    info '                   it will slow down the future installations' && \
    echo && \
    die 'require one option'
    exit 1
fi



# 开始安装
rm -rf '/etc/shadowsocks.json'
rm -rf '/var/run/shadowsocks.pid'
rm -rf '/var/log/shadowsocks.log'

prepare_source "$ss_source_url"
install_require 'pcre-devel'
install_require 'c-ares-devel'
install_require 'libev-devel'
install_require 'libsodium-devel'
install_require 'mbedtls-devel'

set_user_dir 'root' "$install_dir"
set_user_file 'root' "$install_dir/shadowsocks.json"
set_user_file 'root' "$install_dir/ssserver.log"
set_user_file 'root' "$install_dir/${service_name}.service"

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
    "user": "nobody"
    "reuse_port": true,
    "mode": "tcp_and_udp"
}
EOF

cd "$install_dir"
cat << EOF > "${service_name}.service"
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
ExecStart=$install_dir/bin/ss-server -c "$install_dir/shadowsocks.json"--pid-file "$install_dir/ssserver.pid" --log-file "$install_dir/ssserver.log" -q -d start
ExecReload=$install_dir/bin/ss-server -c "$install_dir/shadowsocks.json" --pid-file "$install_dir/ssserver.pid" --log-file "$install_dir/ssserver.log" -q -d restart
ExecStop=$install_dir/bin/ss-server -c "$install_dir/shadowsocks.json" --pid-file "$install_dir/ssserver.pid" --log-file "$install_dir/ssserver.log" -q -d stop

LimitNOFILE=65535
Restart=on-failure
PrivateTmp=true
EOF

cp -f "$install_dir/${service_name}.service" "/usr/lib/systemd/system/${service_name}.service"
systemctl enable "${service_name}.service"
systemctl daemon-reload
systemctl start "${service_name}.service"
systemctl status -l "${service_name}.service"

"$install_dir/bin/ss-server" -h | head -n 5

show_listen
