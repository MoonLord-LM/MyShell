#!/bin/bash
source ./My.sh

# Shadowsocks 3.2.0 在线安装
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_3.2.0.sh
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_3.2.0.sh --delete_exist


# 参数设置
ss_version='3.2.0'
ss_local_port='9998'
ss_server_port='10001'
ss_server_password="Ecs1312357@SS"
ss_source_url='https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.2.0/shadowsocks-libev-3.2.0.tar.gz'


# 开始安装
install_dir="/usr/local/shadowsocks/shadowsocks-$ss_version"
source_dir="shadowsocks-libev-$ss_version"
ss_config_file="$install_dir/shadowsocks.json"
ss_log_file="$install_dir/ssserver.log"
ss_run_script="$install_dir/run.sh"

if [ "$1" == "--delete_exist" ];then
    sudo unset_autorun "sh \"$ss_run_script\""
    sudo rm -rf "$install_dir"
fi

rm -rf '/etc/shadowsocks.json'
rm -rf '/var/run/shadowsocks.pid'
rm -rf '/var/log/shadowsocks.log'

if [ -d "$install_dir" ];then
    die '[ Error ] install_dir exists!'
fi

prepare_source "$ss_source_url"
install_require 'c-ares-devel'
install_require 'libev-devel'
install_require 'libsodium-devel'
install_require 'mbedtls-devel'

set_user_dir 'root' "$install_dir"
set_user_file 'root' "$ss_config_file"
set_user_file 'root' "$ss_log_file"
set_user_file 'root' "$ss_run_script"

cd "$source_dir"
./configure \
 --prefix="$install_dir" \
 --exec-prefix="$install_dir" \
 --sysconfdir="$install_dir" \
 --localstatedir="$install_dir" \
 --runstatedir="$install_dir" \
 --disable-documentation \
 2>&1 | tee 'configure.log'
make -j `grep 'processor' '/proc/cpuinfo' | wc -l` \
 2>&1 | tee 'make.log'
make install

# https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File
# https://github.com/shadowsocks/shadowsocks/wiki/Configure-Multiple-Users
cd "$install_dir"
cat << EOF > "$ss_config_file"
{
    "server": "0.0.0.0",
    "server_port": $ss_server_port,
    "local_address": "0.0.0.0",
    "local_port": $ss_local_port,
    "password": "$ss_server_password",
    "timeout": 300,
    "method": "aes-256-gcm",
    "fast_open": true,
    "reuse_port": true,
    "mode": "tcp_and_udp",
    "user": "nobody"
}
EOF

cat << EOF > "$ss_run_script"
#!/bin/bash
setsid $install_dir/bin/ss-server -c "$ss_config_file" > "$ss_log_file" 2>&1
EOF

setsid sh "$ss_run_script"

set_autorun "sh \"$ss_run_script\""

show_listen