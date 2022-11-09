#!/bin/bash

# Redis
# 开源地址：https://github.com/redis
# 在线安装：wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/redis.sh' | bash



# 参数设置：
redis_conf_file='/etc/redis/redis.conf'
redis_password='Redis@6379'



# 加载函数：
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
check_command_exist 'redis-server' || install_software 'redis-server'
redis-server --version
if [ $? -ne 0 ]; then
    log_error 'redis-server install failed, quit now'
    exit 1
fi

sed -i '/bind 127.0.0.1/d' "$redis_conf_file"
sed -i '/requirepass/d'    "$redis_conf_file" && echo "$redis_password" >> "$redis_conf_file"
sed -i '/protected-mode/d' "$redis_conf_file" && echo 'protected-mode no' >> "$redis_conf_file"

cat "$redis_conf_file" | grep 'bind 127.0.0.1'
cat "$redis_conf_file" | grep 'requirepass'
cat "$redis_conf_file" | grep 'protected-mode'



# 启动服务：
systemctl restart 'redis-server'
systemctl enable 'redis-server'
systemctl status --no-pager 'redis-server'

show_tcp_listening


