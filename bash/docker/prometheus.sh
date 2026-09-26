#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/prometheus.sh' | bash

# Prometheus
# https://github.com/prometheus/prometheus





# ———————————————————————— Config ————————————————————————
prometheus_container_name='prometheus'
prometheus_image='prom/prometheus:latest'
prometheus_data_dir='/var/lib/prometheus'

prometheus_config_file='/etc/prometheus.yml'
prometheus_port=19090

node_exporter_container_name='prometheus_node_exporter'
node_exporter_image='prom/node-exporter:latest'
node_exporter_port=19100

nginx_exporter_container_name='prometheus_nginx_exporter'
nginx_exporter_image='nginx/nginx-prometheus-exporter:latest'
nginx_exporter_port=19113
nginx_host='localhost'
nginx_port=80

mysqld_exporter_container_name='prometheus_mysql_exporter'
mysqld_exporter_image='prom/mysqld-exporter:latest'
mysqld_exporter_port=19104
mysql_host='localhost'
mysql_port=13306
mysql_user='admin'
mysql_password="${MYSQL_PASSWORD:-}"

redis_exporter_container_name='prometheus_redis_exporter'
redis_exporter_image='oliver006/redis_exporter:latest'
redis_exporter_port=19121
redis_host='localhost'
redis_port=6379
redis_password="${REDIS_PASSWORD:-}"

phpfpm_exporter_container_name='prometheus_phpfpm_exporter'
phpfpm_exporter_image='hipages/php-fpm_exporter:latest'
phpfpm_exporter_port=19253
phpfpm_socket='/run/php/php8.4-fpm.sock'

function prometheus_config_yml(){
    cat <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['host.docker.internal:19100']

  - job_name: 'nginx'
    static_configs:
      - targets: ['host.docker.internal:19113']

  - job_name: 'mysql'
    static_configs:
      - targets: ['host.docker.internal:19104']

  - job_name: 'redis'
    static_configs:
      - targets: ['host.docker.internal:19121']

  - job_name: 'phpfpm'
    static_configs:
      - targets: ['host.docker.internal:19253']
EOF
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist 'docker'
if [ $? -ne 0 ]; then
    log_error 'docker not installed, please install docker first'
    exit 1
fi

docker inspect "$prometheus_container_name" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_info 'prometheus container already exists, quit now'
    exit 0
fi

mkdir -p "$prometheus_data_dir"
chown -R 65534:65534 "$prometheus_data_dir"

mkdir -p "$(dirname "$prometheus_config_file")"
backup_file "$prometheus_config_file"
prometheus_config_yml > "$prometheus_config_file"
if [ $? -ne 0 ]; then
    log_error 'prometheus config file create failed, quit now'
    exit 1
fi
chown 65534:65534 "$prometheus_config_file"

docker inspect "$node_exporter_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$node_exporter_image"
    docker run -d \
        --name "$node_exporter_container_name" \
        --restart unless-stopped \
        --network host \
        -v '/:/host:ro,rslave' \
        -v '/proc:/host/proc:ro' \
        -v '/sys:/host/sys:ro' \
        --path.rootfs=/host \
        "$node_exporter_image"
    log_attention "node_exporter installed on port $node_exporter_port"
fi

docker inspect "$nginx_exporter_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$nginx_exporter_image"
    docker run -d \
        --name "$nginx_exporter_container_name" \
        --restart unless-stopped \
        -p "$nginx_exporter_port:9113" \
        -e "SCRAPE_URI=http://${nginx_host}:${nginx_port}/nginx_status" \
        "$nginx_exporter_image"
    log_attention "nginx_exporter installed on port $nginx_exporter_port"
fi

if [ -n "$mysql_password" ]; then
    docker inspect "$mysqld_exporter_container_name" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        docker pull "$mysqld_exporter_image"
        docker run -d \
            --name "$mysqld_exporter_container_name" \
            --restart unless-stopped \
            -p "$mysqld_exporter_port:9104" \
            -e "DATA_SOURCE_NAME=${mysql_user}:${mysql_password}@(${mysql_host}:${mysql_port})/" \
            "$mysqld_exporter_image"
        log_attention "mysqld_exporter installed on port $mysqld_exporter_port"
    fi
else
    log_info 'mysql_password is empty, skip mysqld_exporter installation'
fi

docker inspect "$redis_exporter_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$redis_exporter_image"
    if [ -n "$redis_password" ]; then
        docker run -d \
            --name "$redis_exporter_container_name" \
            --restart unless-stopped \
            -p "$redis_exporter_port:9121" \
            -e "REDIS_ADDR=redis://:${redis_password}@${redis_host}:${redis_port}" \
            "$redis_exporter_image"
        log_attention "redis_exporter installed on port $redis_exporter_port (with password)"
    else
        docker run -d \
            --name "$redis_exporter_container_name" \
            --restart unless-stopped \
            -p "$redis_exporter_port:9121" \
            -e "REDIS_ADDR=${redis_host}:${redis_port}" \
            "$redis_exporter_image"
        log_attention "redis_exporter installed on port $redis_exporter_port (no password)"
    fi
fi

docker inspect "$phpfpm_exporter_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$phpfpm_exporter_image"
    docker run -d \
        --name "$phpfpm_exporter_container_name" \
        --restart unless-stopped \
        -p "$phpfpm_exporter_port:9253" \
        -e "PHPFPM_SCHEME=unix" \
        -e "PHPFPM_PATH=${phpfpm_socket}" \
        -v "${phpfpm_socket}:${phpfpm_socket}:ro" \
        "$phpfpm_exporter_image"
    log_attention "phpfpm_exporter installed on port $phpfpm_exporter_port (socket: $phpfpm_socket)"
fi

docker pull "$prometheus_image"
if [ $? -ne 0 ]; then
    log_error 'prometheus image pull failed, quit now'
    exit 1
fi

docker run -d \
    --name "$prometheus_container_name" \
    --restart unless-stopped \
    -p "$prometheus_port:9090" \
    -v "$prometheus_config_file:/etc/prometheus/prometheus.yml" \
    -v "$prometheus_data_dir:/prometheus" \
    "$prometheus_image"
if [ $? -ne 0 ]; then
    log_error 'prometheus container start failed, quit now'
    exit 1
fi

prometheus_server_ip=$(hostname -I | awk '{print $1}')
log_attention "prometheus server ip: ${prometheus_server_ip}"
log_attention "prometheus server port: ${prometheus_port}"
log_attention "prometheus config file: ${prometheus_config_file}"
log_attention "prometheus data dir: ${prometheus_data_dir}"

prometheus_server_url="http://${prometheus_server_ip}:${prometheus_port}"
log_attention "prometheus server url: ${prometheus_server_url}"





# ———————————————————————— Start ————————————————————————
docker ps -a --filter "name=$prometheus_container_name"

show_tcp_listening
