#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/grafana.sh' | bash

# export GRAFANA_PASSWORD="<password>"
# docker rm -f grafana

# Grafana
# https://github.com/grafana/grafana





# ———————————————————————— Config ————————————————————————
grafana_container_name='grafana'
grafana_image='grafana/grafana:latest'
grafana_data_dir='/var/lib/grafana'

grafana_admin_password_file='/etc/grafana/secrets/admin_password'

grafana_ssl_key_file='/etc/grafana/certs/grafana.key'
grafana_ssl_cert_file='/etc/grafana/certs/grafana.crt'

grafana_port=13000
grafana_admin_user='admin'
grafana_admin_password="${GRAFANA_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"

run_uid_gid='472:472'

function grafana_gen_ssl_cert(){
    mkdir -p "$(dirname "$grafana_ssl_key_file")"
    openssl req -newkey rsa:4096 -nodes -keyout "$grafana_ssl_key_file" -x509 -days 365000 -out "$grafana_ssl_cert_file" -subj '/CN=Grafana'
    {
        if_error_then_exit 'grafana_gen_ssl_cert failed, quit now'
    }
    chown "$run_uid_gid" "$grafana_ssl_key_file" "$grafana_ssl_cert_file"
    chmod 600 "$grafana_ssl_key_file"
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi
prepare_common_command





# ———————————————————————— Install ————————————————————————
check_command_exist 'docker'
{
    if_error_then_exit 'docker not installed, please install docker first'
}

log_warn 'if $GRAFANA_PASSWORD is not set, a random password will be generated:'
log_warn 'export GRAFANA_PASSWORD="<password>"'

docker inspect "$grafana_container_name" >'/dev/null' 2>&1
if [ $? -eq 0 ]; then
    log_info 'grafana container already exists, quit now'
    exit 0
fi

prepare_dir "$grafana_data_dir" "$run_uid_gid"
{
    if_error_then_exit 'grafana data dir create failed, quit now'
}

prepare_dir "$(dirname "$grafana_admin_password_file")" "$run_uid_gid"
{
    if_error_then_exit 'grafana secrets dir create failed, quit now'
}

update_file "$grafana_admin_password_file" "$grafana_admin_password" "$run_uid_gid" '600'
{
    if_error_then_exit 'grafana password file create failed, quit now'
}

docker pull "$grafana_image"
{
    if_error_then_exit 'grafana image pull failed, quit now'
}

grafana_gen_ssl_cert

docker run -d \
    --user "$run_uid_gid" \
    --name "$grafana_container_name" \
    --restart unless-stopped \
    -p "$grafana_port:3000" \
    -v "${grafana_ssl_key_file}:/etc/grafana/certs/grafana.key:ro" \
    -v "${grafana_ssl_cert_file}:/etc/grafana/certs/grafana.crt:ro" \
    -v "$grafana_data_dir:/var/lib/grafana" \
    -v "${grafana_admin_password_file}:/run/secrets/grafana_admin_password:ro" \
    -e "GF_SERVER_PROTOCOL=https" \
    -e "GF_SERVER_CERT_KEY=/etc/grafana/certs/grafana.key" \
    -e "GF_SERVER_CERT_FILE=/etc/grafana/certs/grafana.crt" \
    -e "GF_SECURITY_ADMIN_USER=$grafana_admin_user" \
    -e "GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password" \
    -e "GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel,grafana-clock-panel,natel-discrete-panel,briangann-gauge-panel" \
    "$grafana_image"
{
    if_error_then_exit 'grafana container start failed, quit now'
}

grafana_server_name=$(hostname)
grafana_server_ip=$(hostname -I | awk '{print $1}')

log_attention "grafana server name: ${grafana_server_name}"
log_attention "grafana server ip: ${grafana_server_ip}"
log_attention "grafana server port: ${grafana_port}"

log_attention "grafana dashboard url: https://${grafana_server_ip}:${grafana_port}"
log_attention "grafana user: ${grafana_admin_user}"
log_attention "grafana password: ${grafana_admin_password}"

log_attention "grafana data dir: ${grafana_data_dir}"





# ———————————————————————— Start ————————————————————————
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
log_info "docker logs $grafana_container_name:" && docker logs "$grafana_container_name"

show_tcp_listening
