#!/bin/bash

# Cloudflare Tunnel client
# 开源地址：https://github.com/cloudflare/cloudflared
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/cloudflared/server-s1.sh' | bash



# Cloudflare Tunnels
# 管理界面：https://one.dash.cloudflare.com/2d295aefa3699c7b878cf0468beaf53e/access/tunnels
# 帮助文档：https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/local-management/ingress/



# 参数设置：
s1_access='eyJhIjoiMmQyOTVhZWZhMzY5OWM3Yjg3OGNmMDQ2OGJlYWY1M2UiLCJ0IjoiZDdiYTZiMzItMGI2NS00MDZiLWFjYTgtMmM0M2JhZDk4NzViIiwicyI6IlltSmpaalk1TmpZdE1XWXhaUzAwWXpJd0xUazBOREl0TVRBeU5URXpZV0V6WXpKaSJ9'



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
check_command_exist 'cloudflared'
if [ $? -ne 0 ]; then
    cd '/tmp' &&
    curl -L --output 'cloudflared.deb' 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb' && \
    dpkg -i 'cloudflared.deb'
fi



# 启动服务：
cloudflared service uninstall > '/dev/null' 2>&1
cloudflared service install "$s1_access"

show_tcp_listening


