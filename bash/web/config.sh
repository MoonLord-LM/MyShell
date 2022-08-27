#!/bin/bash

# 自定义配置
# 配置 WEB 站点支持 PHP
# 执行配置：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/config.sh' | bash



# 参数设置：
conf_resource='https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/nginx'
ssl_resource='https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/web/nginx/ssl'



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
site_default_path='/etc/nginx/sites-enabled/default'
site_available_path='/etc/nginx/sites-available'
site_enabled_path='/etc/nginx/sites-enabled'

rm -rf "$site_default_path"
mkdir -p "$site_available_path"
mkdir -p "$site_enabled_path"
mkdir -p "$ssl_cert_path"

# 【default】
wget -O "$site_available_path/default.conf" --timeout=10 --no-cache "$conf_resource/default.conf"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$site_available_path/default.conf\", quit now"
    exit 1
fi
ln -s "$site_available_path/default.conf" "$site_enabled_path/default.conf"

# 【moonlord.cc】
wget -O "$site_available_path/moonlord.cc.conf" --timeout=10 --no-cache "$conf_resource/moonlord.cc.conf"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$site_available_path/moonlord.cc.conf\", quit now"
    exit 1
fi
ln -s "$site_available_path/moonlord.cc.conf" "$site_enabled_path/moonlord.cc.conf"

# 【www.moonlord.cc】
wget -O "$site_available_path/defwww.moonlord.ccault.conf" --timeout=10 --no-cache "$conf_resource/www.moonlord.cc.conf"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$site_available_path/www.moonlord.cc.conf\", quit now"
    exit 1
fi
ln -s "$site_available_path/www.moonlord.cc.conf" "$site_enabled_path/www.moonlord.cc.conf"

# 【ssl】
ssl_cert_path='/etc/nginx/ssl'
wget -O "$ssl_cert_path/moonlord.cc.crt" --timeout=10 --no-cache "$ssl_resource/moonlord.cc.crt"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$ssl_cert_path/moonlord.cc.crt\", quit now"
    exit 1
fi
wget -O "$ssl_cert_path/moonlord.cc.key" --timeout=10 --no-cache "$ssl_resource/moonlord.cc.key"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$ssl_cert_path/moonlord.cc.key\", quit now"
    exit 1
fi
wget -O "$ssl_cert_path/www.moonlord.cc.crt" --timeout=10 --no-cache "$ssl_resource/www.moonlord.cc.crt"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$ssl_cert_path/www.moonlord.cc.crt\", quit now"
    exit 1
fi
wget -O "$ssl_cert_path/www.moonlord.cc.key" --timeout=10 --no-cache "$ssl_resource/www.moonlord.cc.key"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$ssl_cert_path/www.moonlord.cc.key\", quit now"
    exit 1
fi

# 【php】
web_root_path='/var/www/html'
mkdir -p "$web_root_path"
echo '<?php phpinfo(); ?>' > "$web_root_path/index.php"
if [ $? -ne 0 ]; then
    log_error "file create failed: \"$web_root_path/index.php\", quit now"
    exit 1
fi



# 启动服务：
systemctl enable 'nginx'
systemctl restart 'nginx'
systemctl status --no-pager 'nginx'

show_tcp_listening


