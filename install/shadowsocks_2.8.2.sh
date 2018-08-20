#!/bin/bash
source ./My.sh

# Shadowsocks 2.8.2 在线安装
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_2.8.2.sh --install
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_2.8.2.sh --reinstall
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_2.8.2.sh --clean_cache


# 参数设置
ss_version='2.8.2'
ss_local_port='9999'
ss_server_port='10000'
ss_server_password='Ecs1312357@SS'



# 选项解析
service_name="ss-$ss_server_port"
source_name="shadowsocks-$ss_version"
install_dir="/usr/local/shadowsocks/shadowsocks-$ss_version"

if [ "$1" == "--reinstall" ]; then
    sudo systemctl stop "${service_name}.service"
    sudo systemctl disable "${service_name}.service"
    sudo rm -rf "/usr/lib/systemd/system/${service_name}.service"
    sudo rm -rf "$install_dir"
    sudo systemctl daemon-reload
elif [ "$1" == "--clean_cache" ]; then
    notice 'nothing to do'
    show_disk_usage "$install_dir"
    exit 0
elif [ "$1" == "--install" ]; then
    if [ -d "$install_dir" ]; then
        die '[ Error ] install_dir exists!'
        exit 1
    fi
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

install_require 'python2-dev'
pip install 'yolk' || die '[ Error ] install failed!'
pip install 'm2crypto' || die '[ Error ] install failed!'

tmp=`yolk -V 'shadowsocks' | grep "shadowsocks $ss_version"`
if [ "$tmp" == "" ]; then
    die '[ Error ] ss_version can not be found!'
fi
pip install "shadowsocks==$ss_version" || die '[ Error ] install failed!'

set_user_dir 'root' "$install_dir"
set_user_file 'root' "$install_dir/shadowsocks.json"
set_user_file 'root' "$install_dir/ssserver.log"
set_user_file 'root' "$install_dir/${service_name}.service"

# https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File
# https://github.com/shadowsocks/shadowsocks/wiki/Configure-Multiple-Users
cd "$install_dir"
cat << EOF > "shadowsocks.json"
{
    "server": "::",
    "server_port": $ss_server_port,
    "local_address": "::",
    "local_port": $ss_local_port,
    "password": "$ss_server_password",
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": true,
    "workers": `grep 'processor' '/proc/cpuinfo' | wc -l`
}
EOF

shadowsocks_shell_py=`find / -type f -name 'shell.py' | grep '/site-packages/shadowsocks/'`
if [ "$shadowsocks_shell_py" == "" ]; then
    die '[ Error ] shadowsocks_shell_py can not be found!'
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
cat << EOF > "${service_name}.service"
[Unit]
Description=Shadowsocks Server
After=syslog.target
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
User=root
Group=root

Type=simple
PIDFile=$install_dir/ssserver.pid

ExecStart=cd "$install_dir" && ./ssserver -c "shadowsocks.json" --pid-file "ssserver.pid" --log-file "ssserver.log" --user nobody -q -d start
ExecReload=cd "$install_dir" && ./ssserver --pid-file "ssserver.pid" -d restart
ExecStop=cd "$install_dir" && ./ssserver --pid-file "ssserver.pid" -d stop

LimitNOFILE=65535
Restart=on-failure
PrivateTmp=true
EOF

cp -f "$install_dir/${service_name}.service" "/usr/lib/systemd/system/${service_name}.service"
systemctl enable "${service_name}.service"
systemctl daemon-reload
systemctl start "${service_name}.service"
systemctl status -l "${service_name}.service"

"$install_dir/ssserver" --version

show_listen