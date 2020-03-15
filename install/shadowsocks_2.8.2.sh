#!/bin/bash
source ./My.sh

# Shadowsocks 2.8.2 在线安装
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_2.8.2.sh



# 参数设置
ss_version='2.8.2'
ss_server_port='10000'
ss_server_password='Ecs1312357@SS'



# 卸载清理
service_name="ssserver$ss_server_port.service"
source_name="shadowsocks-$ss_version"
install_dir="/usr/local/shadowsocks/shadowsocks-$ss_version"

service_file="/usr/lib/systemd/system/$service_name"
if [ -f $service_file ]; then
    sudo systemctl stop "$service_name"
    sudo systemctl disable "$service_name"
    sudo systemctl daemon-reload
    sudo rm -rf '/root/.cache/pip'
    sudo rm -rf '/etc/shadowsocks.json'
    sudo rm -rf '/var/run/shadowsocks.pid'
    sudo rm -rf '/var/log/shadowsocks.log'
    sudo rm -rf "$install_dir"
    sudo rm -rf "$service_file"
fi



# 开始安装
install_require 'm2crypto'

tmp=`pip search shadowsocks | grep "shadowsocks ($ss_version)"`
if [ "$tmp" == "" ]; then
    die '[ Error ] ss_version can not be found!'
    exit 1
fi

pip uninstall "shadowsocks==$ss_version" -y
pip install "shadowsocks==$ss_version"
if [ $? -ne 0 ]; then
    die '[ Error ] pip install shadowsocks failed!'
    exit 1
fi

set_user_dir 'root' "$install_dir"
set_user_file 'root' "$install_dir/shadowsocks.json"
set_user_file 'root' "$install_dir/ssserver.log"
set_user_file 'root' "$install_dir/$service_name"

# https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File
# https://github.com/shadowsocks/shadowsocks/wiki/Configure-Multiple-Users
cd "$install_dir"
cat << EOF > "shadowsocks.json"
{
    "server": "0.0.0.0",
    "server_port": $ss_server_port,
    "password": "$ss_server_password",
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": true,
    "workers": `grep 'processor' '/proc/cpuinfo' | wc -l`,
    "user": "nobody"
}
EOF

shadowsocks_shell_py=`find / -type f -name 'shell.py' | grep '/site-packages/shadowsocks/'`
if [ "$shadowsocks_shell_py" == "" ]; then
    die '[ Error ] shadowsocks_shell_py can not be found!'
    exit 1
fi
modify_config_file "$shadowsocks_shell_py" \
 "    config\['pid-file'\] = config.get('pid-file', '/var/run/shadowsocks.pid')" \
 "    config\['pid-file'\] = config.get('pid-file', '$install_dir/ssserver.pid')"
modify_config_file "$shadowsocks_shell_py" \
 "    config\['log-file'\] = config.get('log-file', '/var/log/shadowsocks.log')" \
 "    config\['log-file'\] = config.get('log-file', '$install_dir/ssserver.log')"
cat "$shadowsocks_shell_py" | grep "$install_dir"

cp -f '/usr/bin/ssserver' "$install_dir/ssserver"
cp -f '/usr/bin/sslocal' "$install_dir/sslocal"

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

ExecStartPre=$install_dir/ssserver --version
ExecStart=$install_dir/ssserver -c "$install_dir/shadowsocks.json" --pid-file "$install_dir/ssserver.pid" --log-file "$install_dir/ssserver.log" -q -d start
ExecReload=$install_dir/ssserver -c "$install_dir/shadowsocks.json" --pid-file "$install_dir/ssserver.pid" --log-file "$install_dir/ssserver.log" -q -d restart
ExecStop=$install_dir/ssserver -c "$install_dir/shadowsocks.json" --pid-file "$install_dir/ssserver.pid" --log-file "$install_dir/ssserver.log" -q -d stop

LimitNOFILE=65535
Restart=on-failure
PrivateTmp=true
EOF

cp -f "$install_dir/$service_name" "$service_file"
systemctl enable "$service_name"
systemctl daemon-reload
systemctl start "$service_name"
systemctl status -l "$service_name"

"$install_dir/ssserver" --version

show_disk_usage "$install_dir"
show_listen
