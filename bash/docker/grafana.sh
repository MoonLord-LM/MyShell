#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/grafana.sh' | bash

# docker rm -f grafana

# Grafana
# https://github.com/grafana/grafana





# ———————————————————————— Config ————————————————————————
grafana_container_name='grafana'
grafana_image='grafana/grafana:latest'
grafana_data_dir='/var/lib/grafana'

grafana_secrets_dir='/etc/grafana/secrets'
grafana_admin_password_file="${grafana_secrets_dir}/admin_password"

grafana_port=13000
grafana_admin_user='admin'
grafana_admin_password="${GRAFANA_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"

run_uid_gid='472:472'




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

log_warn 'require $GRAFANA_PASSWORD, if not set, a random password will be generated:'
log_warn 'export GRAFANA_PASSWORD="<password>"'

docker inspect "$grafana_container_name" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_info 'grafana container already exists, quit now'
    exit 0
fi

prepare_dir "$grafana_data_dir" "$run_uid_gid"
if [ $? -ne 0 ]; then
    log_error 'grafana data dir create failed, quit now'
    exit 1
fi

prepare_dir "$grafana_secrets_dir" "$run_uid_gid"
if [ $? -ne 0 ]; then
    log_error 'grafana secrets dir create failed, quit now'
    exit 1
fi

update_file "$grafana_admin_password_file" "$grafana_admin_password" "$run_uid_gid" '600'
if [ $? -ne 0 ]; then
    log_error 'grafana password file create failed, quit now'
    exit 1
fi

docker pull "$grafana_image"
if [ $? -ne 0 ]; then
    log_error 'grafana image pull failed, quit now'
    exit 1
fi

docker run -d \
    --user "$run_uid_gid" \
    --name "$grafana_container_name" \
    --restart unless-stopped \
    -p "$grafana_port:3000" \
    -v "$grafana_data_dir:/var/lib/grafana" \
    -v "${grafana_admin_password_file}:/run/secrets/grafana_admin_password:ro" \
    -e "GF_SECURITY_ADMIN_USER=$grafana_admin_user" \
    -e "GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password" \
    -e "GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel,grafana-clock-panel,natel-discrete-panel,briangann-gauge-panel" \
    "$grafana_image"
if [ $? -ne 0 ]; then
    log_error 'grafana container start failed, quit now'
    exit 1
fi

grafana_server_name=$(hostname)
grafana_server_ip=$(hostname -I | awk '{print $1}')

log_attention "grafana server name: ${grafana_server_name}"
log_attention "grafana server ip: ${grafana_server_ip}"
log_attention "grafana server port: ${grafana_port}"
log_attention "grafana data dir: ${grafana_data_dir}"
log_attention "grafana user: ${grafana_admin_user}"
log_attention "grafana password: ${grafana_admin_password}"

grafana_server_url="http://${grafana_server_ip}:${grafana_port}"
log_attention "grafana server url: ${grafana_server_url}"





# ———————————————————————— Start ————————————————————————
show_tcp_listening

log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a

log_info "docker logs $grafana_container_name:" && docker logs "$grafana_container_name"
