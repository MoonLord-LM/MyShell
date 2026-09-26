#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/prometheus.sh' | bash

# Prometheus Server
# https://github.com/prometheus/prometheus





# ———————————————————————— Config ————————————————————————
prometheus_container_name='prometheus'
prometheus_image='prom/prometheus:latest'
prometheus_data_dir='/var/lib/prometheus'

prometheus_config_file='/etc/prometheus.yml'
prometheus_port=19090

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
      - targets: ['localhost:9100']

  - job_name: 'mysql'
    static_configs:
      - targets: ['localhost:13306']

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:6379']

  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:80']

  - job_name: 'php-fpm'
    static_configs:
      - targets: ['localhost:9000']
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

mkdir -p "$(dirname "$prometheus_config_file")"
mkdir -p "$prometheus_data_dir"

backup_file "$prometheus_config_file"
prometheus_config_yml > "$prometheus_config_file"
if [ $? -ne 0 ]; then
    log_error 'prometheus config file create failed, quit now'
    exit 1
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





# ———————————————————————— Start ————————————————————————
docker ps -a --filter "name=$prometheus_container_name"

show_tcp_listening
