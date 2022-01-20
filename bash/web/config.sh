#!/bin/bash

# 配置 WEB 站点
# 在线执行：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/config.sh' | bash



# 配置参数：
mkdir -p '/etc/nginx/sites-available'
wget -O '/etc/nginx/sites-available/nginx.conf' --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/nginx.conf'

mkdir -p '/etc/nginx/ssl'
wget -O '/etc/nginx/ssl/server.crt' --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/server.crt'
wget -O '/etc/nginx/ssl/server.key' --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/server.key'

ln -s '/etc/nginx/sites-available/nginx.conf' '/etc/nginx/sites-enabled/nginx.conf'
rm -rf '/etc/nginx/sites-enabled/default'

mkdir -p '/var/www/php'
echo '<?php phpinfo(); ?>' > '/var/www/php/index.php'



# 启动服务：
systemctl enable 'nginx'
systemctl restart 'nginx'
systemctl status --no-pager 'nginx'


