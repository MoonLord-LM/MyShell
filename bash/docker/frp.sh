#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/frp.sh' | bash

# export FRP_TOKEN='<token>'
# export FRP_DASHBOARD_PASSWORD='<password>'
# docker rm -f frp

# Frp
# https://github.com/fatedier/frp
# https://gofrp.org/zh-cn/docs/reference/server-configures/





# ———————————————————————— Config ————————————————————————
frp_container_name='frp'
frp_image='fatedier/frps:v0.71.0'
frp_config_dir='/etc/frp'
frp_data_dir='/var/lib/frp'
frp_config_file="${frp_config_dir}/frp.toml"
frp_client_demo_config_file="${frp_config_dir}/frp-client-demo.toml"
frp_log_file="${frp_data_dir}/frp.log"

frp_ssl_key="${frp_config_dir}/frp.key"
frp_ssl_cert="${frp_config_dir}/frp.crt"

frp_bind_port=17000
frp_vhost_https_port=17443
frp_dashboard_port=17500

frp_token="${FRP_TOKEN:-$(head -c 32 /dev/urandom | base64 -w 0)}"
frp_token_escaped=$(printf '%s' "$frp_token" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
frp_dashboard_user='admin'
frp_dashboard_password="${FRP_DASHBOARD_PASSWORD:-$(head -c 32 /dev/urandom | base64 -w 0)}"
frp_dashboard_password_escaped=$(printf '%s' "$frp_dashboard_password" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

run_uid_gid='65534:65534'

function generate_frp_server_config(){
    cat <<EOF
bindAddr = "::"
bindPort = ${frp_bind_port}
vhostHTTPSPort = ${frp_vhost_https_port}

auth.method = "token"
auth.token = "${frp_token_escaped}"

transport.tls.force = true
transport.tls.keyFile = "${frp_ssl_key}"
transport.tls.certFile = "${frp_ssl_cert}"
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
webServer.password = "${frp_dashboard_password_escaped}"
webServer.tls.keyFile = "${frp_ssl_key}"
webServer.tls.certFile = "${frp_ssl_cert}"
EOF
}

function generate_frp_client_demo_config(){
    cat <<EOF
serverAddr = "${frp_server_ip}"
serverPort = ${frp_bind_port}

auth.method = "token"
auth.token = "${frp_token_escaped}"

transport.poolCount = 20
transport.dialServerKeepalive = 60
transport.tcpMuxKeepaliveInterval = 60
transport.heartbeatInterval = 60
transport.tls.enable = true

[[proxies]]
name = "local-8443-to-server-${frp_vhost_https_port}"
type = "https"

localIP = "127.0.0.1"
localPort = 8443

customDomains = ["*"]
EOF
}





# ———————————————————————— Init ————————————————————————
tmp_file="/tmp/MyShell_My.sh_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.sh"
wget -O "$tmp_file" --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh'
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: download failed, quit now' && echo -ne '\e[0m'
    rm -f "$tmp_file"
    exit 1
fi
source "$tmp_file"
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    rm -f "$tmp_file"
    exit 1
fi
rm -f "$tmp_file"
prepare_common_command





# ———————————————————————— Install ————————————————————————
check_command_exist 'docker'
{
    if_error_then_exit 'docker not installed, please install docker first'
}

log_warn 'if $FRP_TOKEN is not set, a random token will be generated:'
log_warn "export FRP_TOKEN='<token>'"

log_warn 'if $FRP_DASHBOARD_PASSWORD is not set, a random password will be generated:'
log_warn "export FRP_DASHBOARD_PASSWORD='<password>'"

docker inspect "$frp_container_name" >'/dev/null' 2>&1
if [ $? -eq 0 ]; then
    log_info 'frp server container already exists, quit now'
    exit 0
fi

prepare_dir "$frp_data_dir" "$run_uid_gid"
{
    if_error_then_exit 'frp data directory creation failed, quit now'
}

generate_ssl_cert 'Frp' "$frp_ssl_key" "$frp_ssl_cert" "$run_uid_gid"
{
    if_error_then_exit 'frp ssl cert generate failed, quit now'
}

update_file "$frp_config_file" "$(generate_frp_server_config)" "$run_uid_gid" '600'
{
    if_error_then_exit 'frp server config file creation failed, quit now'
}
log_info "frp server config file: ${frp_config_file} (mode 600)"

update_file "$frp_client_demo_config_file" "$(generate_frp_client_demo_config)" "$run_uid_gid" '600'
{
    if_error_then_exit 'frp client demo config file creation failed, quit now'
}

docker pull "$frp_image"
{
    if_error_then_exit 'frp server image pull failed, quit now'
}

docker run -d \
    --user "$run_uid_gid" \
    --name "$frp_container_name" \
    --restart unless-stopped \
    --network host \
    -v "$frp_config_file:/etc/frp/frp.toml:ro" \
    -v "$frp_data_dir:/var/lib/frp" \
    -v "$frp_ssl_key:/etc/frp/frp.key:ro" \
    -v "$frp_ssl_cert:/etc/frp/frp.crt:ro" \
    "$frp_image" \
    -c /etc/frp/frp.toml
{
    if_error_then_exit 'frp server container start failed, quit now'
}

frp_server_name=$(hostname)
frp_server_ip=$(get_system_ip)

log_important "frp server name: ${frp_server_name}"
log_important "frp server ip: ${frp_server_ip}"
log_important "frp server bind port: ${frp_bind_port}"
log_important "frp server vhost https port: ${frp_vhost_https_port}"
log_secret "frp server token: ${frp_token}"

log_important "frp server dashboard url: https://${frp_server_ip}:${frp_dashboard_port}"
log_important "frp server dashboard user: ${frp_dashboard_user}"
log_secret "frp server dashboard password: ${frp_dashboard_password}"

log_important "frp config directory: ${frp_config_dir}"
log_important "frp data directory: ${frp_data_dir}"
log_important "frp config file: ${frp_config_file}"
log_important "frp log file: ${frp_log_file}"
log_important "frp ssl key file: ${frp_ssl_key}"
log_important "frp ssl cert file: ${frp_ssl_cert}"

echo
log_important "frp client demo config file: ${frp_client_demo_config_file}"
if [ -t 2 ]; then
    log_success "==================== frp-client-demo.toml - begin ===================="
    log_success "$(generate_frp_client_demo_config)"
    log_success "==================== frp-client-demo.toml - end ===================="
fi
echo

log_info "client run command: frpc.exe -c frpc.toml"
log_info "client example local url: https://127.0.0.1:8443"
log_info "client example publish url: https://${frp_server_ip}:${frp_vhost_https_port}"





# ———————————————————————— Start ————————————————————————
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
log_info "docker logs $frp_container_name:" && docker logs "$frp_container_name"

show_tcp_listening
