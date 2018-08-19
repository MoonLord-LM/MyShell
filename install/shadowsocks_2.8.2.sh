#!/bin/bash
source ./My.sh

# Shadowsocks 2.8.2 在线安装
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_2.8.2.sh
# sudo chmod -R 777 ./ && sudo sh ./shadowsocks_2.8.2.sh --delete_exist


# 参数设置
ss_version='2.8.2'
ss_local_port='9999'
ss_server_port='10000'
ss_server_password="Ecs1312357@SS"


# 开始安装
install_dir="/usr/local/shadowsocks/shadowsocks-$ss_version"
ss_config_file="$install_dir/shadowsocks.json"
ss_pid_file="$install_dir/ssserver.pid"
ss_log_file="$install_dir/ssserver.log"
ss_run_script="$install_dir/run.sh"
ss_workers=`grep 'processor' '/proc/cpuinfo' | wc -l`

if [ "$1" == "--delete_exist" ];then
    sudo ssserver -d stop
    sudo unset_autorun "sh \"$ss_run_script\""
    sudo rm -rf "$install_dir"
    sudo pip uninstall "shadowsocks==$ss_version" -y
fi

rm -rf '/etc/shadowsocks.json'
rm -rf '/var/run/shadowsocks.pid'
rm -rf '/var/log/shadowsocks.log'

if [ -d "$install_dir" ];then
    die '[ Error ] install_dir exists!'
fi

pip install 'yolk' || die '[ Error ] install failed!'
pip install 'm2crypto' || die '[ Error ] install failed!'

tmp=`yolk -V 'shadowsocks' | grep "shadowsocks $ss_version"`
if [ "$tmp" == "" ]; then
    die '[ Error ] ss_version can not be found!'
fi

pip install "shadowsocks==$ss_version" || die '[ Error ] install failed!'

set_user_dir 'root' "$install_dir"
set_user_file 'root' "$ss_config_file"
set_user_file 'root' "$ss_log_file"
set_user_file 'root' "$ss_run_script"

# https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File
# https://github.com/shadowsocks/shadowsocks/wiki/Configure-Multiple-Users
cat << EOF > "$ss_config_file"
{
    "server": "::",
    "server_port": $ss_server_port,
    "local_address": "::",
    "local_port": $ss_local_port,
    "password": "$ss_server_password",
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": true,
    "workers": $ss_workers
}
EOF

shadowsocks_shell_py=`find / -type f -name 'shell.py' | grep '/site-packages/shadowsocks/'`
if [ "$shadowsocks_shell_py" == "" ]; then
    die '[ Error ] shadowsocks_shell_py can not be found!'
fi
modify_config_file "$shadowsocks_shell_py" \
 "    config\['pid-file'\] = config.get('pid-file', '/var/run/shadowsocks.pid')" \
 "    config\['pid-file'\] = config.get('pid-file', '$ss_pid_file')"
modify_config_file "$shadowsocks_shell_py" \
 "    config\['log-file'\] = config.get('log-file', '/var/log/shadowsocks.log')" \
 "    config\['log-file'\] = config.get('log-file', '$ss_log_file')"
cat "$shadowsocks_shell_py" | grep "$install_dir"

cat << EOF > "$ss_run_script"
#!/bin/bash
ssserver \
 -c "$ss_config_file" \
 --pid-file "$ss_pid_file" \
 --log-file "$ss_log_file" \
 --user nobody \
 -q \
 -d start
EOF

sh "$ss_run_script"

set_autorun "sh \"$ss_run_script\""

show_listen