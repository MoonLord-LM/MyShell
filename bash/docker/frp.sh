#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/frps.sh' | bash

# docker rm -f frps

# FRP Server
# https://github.com/fatedier/frp





# ———————————————————————— Config ————————————————————————
frps_container_name='frps'
frps_image='thanosme/frps:latest'

frps_config_dir='/etc/frp'
frps_data_dir='/var/lib/frp'
frps_config_file="${frps_config_dir}/frps.toml"
frps_log_file="${frps_data_dir}/frps.log"
frps_store_path="${frps_data_dir}/frps_store.ini"

frps_bind_port=17000
frps_vhost_http_port=17080
frps_dashboard_port=17500

frps_dashboard_user='admin'
frps_dashboard_password="${FRPS_DASHBOARD_PASSWORD:-$(head -c 16 /dev/urandom | base64 -w 0)}"
frps_token="${FRP_TOKEN:-$(head -c 32 /dev/urandom | base64 -w 0)}"

run_uid_gid='65534:65534'

function generate_frps_config_content(){
    cat <<EOF
bindPort = ${frps_bind_port}
vhostHTTPPort = ${frps_vhost_http_port}
authenticationMethod = "token"
token = "${frps_token}"
tlsEnable = true

log.to = "file"
log.file = "${frps_log_file}"
log.level = "info"
log.maxDays = 3

store.path = "${frps_store_path}"

[dashboard]
addr = "::"
port = ${frps_dashboard_port}
user = "${frps_dashboard_user}"
password = "${frps_dashboard_password}"
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

log_warn 'require $FRPS_DASHBOARD_PASSWORD, if not set, a random password will be generated:'
log_warn 'export FRPS_DASHBOARD_PASSWORD="<password>"'

log_warn 'require $FRP_TOKEN, if not set, a random token will be generated:'
log_warn 'export FRP_TOKEN="<token>"'

docker inspect "$frps_container_name" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_info 'frp server container already exists, quit now'
    exit 0
fi

mkdir -p "$frps_config_dir"
if [ $? -ne 0 ]; then
    log_error 'frp config directory creation failed, quit now'
    exit 1
fi
chown "$run_uid_gid" "$frps_config_dir"

mkdir -p "$frps_data_dir"
if [ $? -ne 0 ]; then
    log_error 'frp data directory creation failed, quit now'
    exit 1
fi
chown "$run_uid_gid" "$frps_data_dir"

generate_frps_config_content > "$frps_config_file"
if [ $? -ne 0 ]; then
    log_error 'frp server config file creation failed, quit now'
    exit 1
fi
chmod 600 "$frps_config_file"
chown "$run_uid_gid" "$frps_config_file"
log_info "FRP server config file: ${frps_config_file} (mode 600)"

docker pull "$frps_image"
if [ $? -ne 0 ]; then
    log_error 'frp server image pull failed, quit now'
    exit 1
fi

docker run -d \
    --user "$run_uid_gid" \
    --name "$frps_container_name" \
    --restart unless-stopped \
    --network host \
    -v "$frps_config_file:/etc/frp/frps.toml:ro" \
    -v "$frps_data_dir:/var/lib/frp" \
    "$frps_image" \
    frps -c /etc/frp/frps.toml

if [ $? -ne 0 ]; then
    log_error 'frp server container start failed, quit now'
    exit 1
fi

frps_server_name=$(hostname)
frps_server_ip=$(hostname -I | awk '{print $1}')

log_attention "frp server name: ${frps_server_name}"
log_attention "frp server dashboard: http://${frps_server_ip}:${frps_dashboard_port}"
log_attention "frp user: ${frps_dashboard_user}"
log_attention "frp password: ${frps_dashboard_password}"

log_attention "frp server bind: ${frps_server_ip}:${frps_bind_port}"
log_attention "frp server vhost http: ${frps_server_ip}:${frps_vhost_http_port}"
log_attention "frp server token: ${frps_token}"

log_attention "frp config directory: ${frps_config_dir}"
log_attention "frp data directory: ${frps_data_dir}"
log_attention "frp config file: ${frps_config_file}"
log_attention "frp log file: ${frps_log_file}"
log_attention "frp store path: ${frps_store_path}"





# ———————————————————————— Start ————————————————————————
show_tcp_listening

log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
