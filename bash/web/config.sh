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
config_resource='https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/nginx'



site_default_conf='/etc/nginx/sites-enabled/default'
rm -rf "$site_default_conf"



site_available_conf='/etc/nginx/sites-available/nginx.conf'
site_enabled_conf='/etc/nginx/sites-enabled/nginx.conf'
wget -O "$site_available_conf" --timeout=10 --no-cache "$config_resource/nginx.conf"
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"$site_available_conf\", quit now"
    exit 1
fi
ln -s "$site_available_conf" "$site_enabled_conf"



ssl_cert_path='/etc/nginx/ssl'
mkdir -p "$ssl_cert_path"
wget -O "$ssl_cert_path/moonlord.cc.crt" --timeout=10 --no-cache "$config_resource/moonlord.cc.crt"
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"$ssl_cert_path/moonlord.cc.crt\", quit now"
    exit 1
fi
wget -O "$ssl_cert_path/moonlord.cc.key" --timeout=10 --no-cache "$config_resource/moonlord.cc.key"
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"$ssl_cert_path/moonlord.cc.key\", quit now"
    exit 1
fi
wget -O "$ssl_cert_path/www.moonlord.cc.crt" --timeout=10 --no-cache "$config_resource/www.moonlord.cc.crt"
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"$ssl_cert_path/www.moonlord.cc.crt\", quit now"
    exit 1
fi
wget -O "$ssl_cert_path/www.moonlord.cc.key" --timeout=10 --no-cache "$config_resource/www.moonlord.cc.key"
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"$ssl_cert_path/www.moonlord.cc.key\", quit now"
    exit 1
fi



web_root_path='/var/www/html'
mkdir -p "$web_root_path"
echo '<?php phpinfo(); ?>' > "$web_root_path/index.php"
if [ $? -ne 0 ]; then
    log_error "file can not be created: \"$web_root_path/index.php\", quit now"
    exit 1
fi



# 启动服务：
systemctl enable 'nginx'
systemctl restart 'nginx'
systemctl status --no-pager 'nginx'


