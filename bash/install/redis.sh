#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/redis.sh' | bash

# export REDIS_PASSWORD="<password>"
# apt remove -y redis-server

# Redis
# https://github.com/redis





# ———————————————————————— Config ————————————————————————
redis_apt_repo_url='https://packages.redis.io'
redis_gpg_key_file='/usr/share/keyrings/packages.redis.io.gpg'
redis_apt_source_file='/etc/apt/sources.list.d/redis.list'

redis_conf_file='/etc/redis/redis.conf'
redis_ssl_key='/etc/redis/ssl/server-key.pem'
redis_ssl_cert='/etc/redis/ssl/server-cert.pem'

redis_server_port=16379
redis_password="${REDIS_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"

run_uid_gid='redis:redis'

function redis_config_cnf(){
    cat <<EOF
supervised systemd

dir /var/lib/redis
dbfilename dump.rdb
logfile /var/log/redis/redis-server.log

bind 0.0.0.0 ::
port 0
tls-port $redis_server_port
tls-key-file $redis_ssl_key
tls-cert-file $redis_ssl_cert
tls-auth-clients no
tls-protocols "TLSv1.2 TLSv1.3"

requirepass $redis_password
protected-mode yes

maxmemory 2gb
maxmemory-policy allkeys-lru

appendonly no
save 600 1
save 300 100
save 120 10000
stop-writes-on-bgsave-error yes
EOF
}

function redis_gen_ssl_cert(){
    mkdir -p $(dirname "$redis_ssl_key")
    openssl req -newkey rsa:4096 -nodes -keyout "$redis_ssl_key" -x509 -days 365000 -out "$redis_ssl_cert" -subj '/CN=Redis'
    {
        if_error_then_exit 'redis_gen_ssl_cert failed, quit now'
    }

    chown "$run_uid_gid" "$redis_ssl_key" "$redis_ssl_cert"
    chmod 600 "$redis_ssl_key"
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi
prepare_common_command





# ———————————————————————— Install ————————————————————————
check_command_exist 'redis-server'
if [ $? -eq 0 ]; then
    log_info 'redis already installed, quit now'
    exit 0
fi

log_warn 'if $REDIS_PASSWORD is not set, a random password will be generated:'
log_warn 'export REDIS_PASSWORD="<password>"'

wget -O- --timeout=120 --no-cache "${redis_apt_repo_url}/gpg" | gpg --dearmor --yes -o "$redis_gpg_key_file"
{
    if_error_then_exit 'redis gpg key download failed, quit now'
}

codename=$(get_system_version_codename)
update_file "$redis_apt_source_file" "deb [signed-by=$redis_gpg_key_file] ${redis_apt_repo_url}/deb $codename main"

install_software 'redis'
{
    if_error_then_exit 'redis install failed, quit now'
}

redis-server --version
{
    if_error_then_exit 'redis version check failed, quit now'
}

redis_gen_ssl_cert

update_file "$redis_conf_file" "$(redis_config_cnf)" "$run_uid_gid" '600'

redis_server_ip=$(hostname -I | awk '{print $1}')
log_attention "redis server ip: ${redis_server_ip}"
log_attention "redis server port: ${redis_server_port}"
log_attention "redis password: ${redis_password}"
log_attention "redis ssl cert: ${redis_ssl_cert}"





# ———————————————————————— Start ————————————————————————
systemctl restart 'redis-server'
systemctl enable 'redis-server'
systemctl status --no-pager 'redis-server'

show_tcp_listening
