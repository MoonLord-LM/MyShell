#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/frp.sh' | bash

# docker rm -f frp

# Frp
# https://github.com/fatedier/frp





# ———————————————————————— Config ————————————————————————
frp_container_name='frp'
frp_image='fatedier/frps:v0.71.0'
frp_config_dir='/etc/frp'
frp_data_dir='/var/lib/frp'
frp_config_file="${frp_config_dir}/frp.toml"
frp_log_file="${frp_data_dir}/frp.log"

frp_bind_port=17000
frp_vhost_http_port=17080
frp_dashboard_port=17500

frp_dashboard_user='admin'
frp_dashboard_password="${FRP_DASHBOARD_PASSWORD:-$(head -c 32 /dev/urandom | base64 -w 0)}"
frp_token="${FRP_TOKEN:-$(head -c 32 /dev/urandom | base64 -w 0)}"

run_uid_gid='65534:65534'

function generate_frp_config_content(){
    cat <<EOF
bindAddr = "::"
bindPort = ${frp_bind_port}
vhostHTTPPort = ${frp_vhost_http_port}

auth.method = "token"
auth.token = "${frp_token}"

transport.tls.force = true
transport.maxPoolCount = 20
transport.tcpKeepalive = 60
transport.tcpMuxKeepaliveInterval = 60
transport.heartbeatTimeout = 180

log.to = "${frp_log_file}"
log.level = "info"
log.maxDays = 3

webServer.addr = "::"
webServer.port = ${frp_dashboard_port}
webServer.user = "${frp_dashboard_user}"
webServer.password = "${frp_dashboard_password}"
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

log_warn 'require $FRP_TOKEN, if not set, a random token will be generated:'
log_warn 'export FRP_TOKEN="<token>"'

log_warn 'require $FRP_DASHBOARD_PASSWORD, if not set, a random password will be generated:'
log_warn 'export FRP_DASHBOARD_PASSWORD="<password>"'

docker inspect "$frp_container_name" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_info 'frp server container already exists, quit now'
    exit 0
fi

mkdir -p "$frp_config_dir"
if [ $? -ne 0 ]; then
    log_error 'frp config directory creation failed, quit now'
    exit 1
fi
chown "$run_uid_gid" "$frp_config_dir"

mkdir -p "$frp_data_dir"
if [ $? -ne 0 ]; then
    log_error 'frp data directory creation failed, quit now'
    exit 1
fi
chown "$run_uid_gid" "$frp_data_dir"

backup_file "$frp_config_file"
generate_frp_config_content > "$frp_config_file"
if [ $? -ne 0 ]; then
    log_error 'frp server config file creation failed, quit now'
    exit 1
fi
chmod 600 "$frp_config_file"
chown "$run_uid_gid" "$frp_config_file"
log_info "frp server config file: ${frp_config_file} (mode 600)"

docker pull "$frp_image"
if [ $? -ne 0 ]; then
    log_error 'frp server image pull failed, quit now'
    exit 1
fi

docker run -d \
    --user "$run_uid_gid" \
    --name "$frp_container_name" \
    --restart unless-stopped \
    --network host \
    -v "$frp_config_file:/etc/frp/frp.toml:ro" \
    -v "$frp_data_dir:/var/lib/frp" \
    "$frp_image" \
    -c /etc/frp/frp.toml
if [ $? -ne 0 ]; then
    log_error 'frp server container start failed, quit now'
    exit 1
fi

frp_server_name=$(hostname)
frp_server_ip=$(hostname -I | awk '{print $1}')

log_attention "frp server name: ${frp_server_name}"
log_attention "frp server bind: ${frp_server_ip}:${frp_bind_port}"
log_attention "frp server vhost http: ${frp_server_ip}:${frp_vhost_http_port}"
log_attention "frp server token: ${frp_token}"

log_attention "frp server dashboard: http://${frp_server_ip}:${frp_dashboard_port}"
log_attention "frp server dashboard user: ${frp_dashboard_user}"
log_attention "frp server dashboard password: ${frp_dashboard_password}"

log_attention "frp config directory: ${frp_config_dir}"
log_attention "frp data directory: ${frp_data_dir}"
log_attention "frp config file: ${frp_config_file}"
log_attention "frp log file: ${frp_log_file}"





# ———————————————————————— Start ————————————————————————
show_tcp_listening

log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a

log_info "docker logs $frp_container_name:" && docker logs "$frp_container_name"
