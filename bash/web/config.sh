#!/bin/bash

# 配置 WEB 站点
# 在线执行：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/config.sh' | bash



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 配置参数：
mkdir -p '/etc/nginx/sites-available'
wget -O '/etc/nginx/sites-available/nginx.conf' --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/nginx.conf'
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"/etc/nginx/sites-available/nginx.conf\", quit now"
    exit 1
fi

mkdir -p '/etc/nginx/ssl'
wget -O '/etc/nginx/ssl/server.crt' --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/server.crt'
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"/etc/nginx/ssl/server.crt\", quit now"
    exit 1
fi
wget -O '/etc/nginx/ssl/server.key' --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/server.key'
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"/etc/nginx/ssl/server.key\", quit now"
    exit 1
fi

ln -s '/etc/nginx/sites-available/nginx.conf' '/etc/nginx/sites-enabled/nginx.conf'
rm -rf '/etc/nginx/sites-enabled/default'

mkdir -p '/var/www/php'
echo '<?php phpinfo(); ?>' > '/var/www/php/index.php'
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"/var/www/php/index.php\", quit now"
    exit 1
fi



# 启动服务：
systemctl enable 'nginx'
systemctl restart 'nginx'
systemctl status --no-pager 'nginx'


