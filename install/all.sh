#!/bin/bash
source ./My.sh

# 全部在线安装
# sudo chmod -R 777 ./ && sudo sh ./all.sh
# sudo chmod -R 777 ./ && sudo sh ./all.sh --delete_exist


# 参数设置
site_root_path='/home/web_root'
php_site_name='moonlord.cn'


# 开始安装
update_repo "$aliyun_repo"
update_pypi "$aliyun_pypi"

if [ "$1" == "--delete_exist" ];then
    sudo sh ./mysql_5.7.23.sh --delete_exist
    sudo sh ./mysql_8.0.12.sh --delete_exist
    sudo sh ./php_5.6.37.sh --delete_exist
    sudo sh ./nginx_1.15.2.sh --delete_exist
    sudo sh ./shadowsocks_2.8.2.sh --delete_exist
else
    sudo sh ./mysql_5.7.23.sh
    sudo sh ./mysql_8.0.12.sh
    sudo sh ./php_5.6.37.sh
    sudo sh ./nginx_1.15.2.sh
    sudo sh ./shadowsocks_2.8.2.sh
fi

set_user_dir 'root' "$site_root_path"
set_user_dir 'php' "$site_root_path/$php_site_name"

tmp=`find '/usr/local/nginx' -type d -name 'vhost' | wc -l`
if [ "$tmp" == "0" ]; then
    die '[ Error ] can not find vhost dir!'
    return
fi
if [ "$tmp" != "1" ]; then
    die '[ Error ] find more than one vhost dir!'
    return
fi
nginx_vhost_dir=`find '/usr/local/nginx' -type d -name 'vhost'`

tmp=`show_listen | grep php | awk -F':' '{print $2}' | awk -F' ' '{print $1}' | wc -l`
if [ "$tmp" == "0" ]; then
    die '[ Error ] can not find php listen port!'
    return
fi
if [ "$tmp" != "1" ]; then
    die '[ Error ] find more than one php listen port!'
    return
fi
php_listen_port=`show_listen | grep php | awk -F':' '{print $2}' | awk -F' ' '{print $1}'`

cd "$nginx_vhost_dir"
openssl genrsa 1024 >"$php_site_name.key"
openssl req -new -key "$php_site_name.key" -out "$php_site_name.csr" << EOF
CN
China
Beijing
GitHub
moonlord.cn
moonlord.cn
me@moonlord.cn
me@moonlord.cn
me@moonlord.cn
EOF
openssl x509 -req -days 365243 -in "$php_site_name.csr" -signkey "$php_site_name.key" -out "$php_site_name.crt"
rm -rf "$php_site_name.csr"

cd "$nginx_vhost_dir"
cat << EOF > "default.conf"
    server {
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page  404 500 502 503 504 /50x.html;
    }
EOF
cat << EOF > "$php_site_name.conf"
    server {
        listen       80;
        listen       443 ssl;
        server_name  $php_site_name *.$php_site_name;
        root         $site_root_path/$php_site_name;

        ssl_certificate      "$nginx_vhost_dir/$php_site_name.crt";
        ssl_certificate_key  "$nginx_vhost_dir/$php_site_name.key";

        location / {
            index  index.php index.html index.htm;
        }

        location ~ .*\.php$ {
            include        fastcgi.conf;
            fastcgi_pass   127.0.0.1:$php_listen_port;
            fastcgi_index  index.php;
        }

        error_page  404  /404.php;

        # if (\$host = "$php_site_name") {
        #     rewrite  ^/(.*)$  \$scheme://www.$php_site_name/\$1 permanent;
        # }

        # if (\$scheme = "http") {
        #     rewrite  ^/(.*)$  https://\$host/\$1 permanent;
        # }
    }
EOF

cd "$site_root_path/$php_site_name"
cat << EOF > "index.php"
<?php
    phpinfo();
?>
EOF

wget "http://www.php.net/favicon.ico"  -O "$site_root_path/$php_site_name/favicon.ico"

tmp=`find '/usr/lib/systemd/system/' -type f -name  'nginx*.service' | wc -l`
if [ "$tmp" == "0" ]; then
    die '[ Error ] can not find nginx service name!'
    return
fi
if [ "$tmp" != "1" ]; then
    die '[ Error ] find more than one nginx service name!'
    return
fi
nginx_service_file=`find '/usr/lib/systemd/system/' -type f -name  'nginx*.service'`
nginx_service_name="${nginx_service_file##*/}"
systemctl restart "$nginx_service_name"

show