#!/bin/bash

# Shadowsocks
# 开源地址：https://github.com/shadowsocks/shadowsocks-libev
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/shadowsocks-libev.sh' | bash



# 参数设置：
function ss_config(){
cat <<EOF
{
    "server":"0.0.0.0",
    "server_port":10000,
    "local_port":10001,
    "password":"Shadowsocks@10000",
    "timeout":30,
    "method":"chacha20-ietf-poly1305"
}
EOF
}



# 开始安装：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
install_common_command

check_system_is_centos
if [ $? -eq 0 ]; then
    yum-config-manager --add-repo 'https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo'
    cd '/etc/yum.repos.d/'
    ls -la
fi

install_software 'shadowsocks-libev'
ss_config > '/etc/shadowsocks-libev/config.json'
systemctl enable 'shadowsocks-libev'
systemctl restart 'shadowsocks-libev'
systemctl status --no-pager 'shadowsocks-libev'


