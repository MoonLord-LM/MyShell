#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/portainer.sh' | bash

# export PORTAINER_PASSWORD='<password>'
# docker rm -f portainer && docker volume rm portainer_data

# Portainer CE
# https://github.com/portainer/portainer
# https://docs.portainer.io/start/install-ce/server/docker/linux
# https://docs.portainer.io/advanced/cli.md





# ———————————————————————— Config ————————————————————————
portainer_container_name='portainer'
portainer_image='portainer/portainer-ce:latest'
portainer_volume_name='portainer_data'
portainer_server_port=19443
portainer_docker_socket_file='/var/run/docker.sock'

portainer_admin_user='admin'
portainer_admin_password="${PORTAINER_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"
portainer_admin_password_file='/etc/portainer/secrets/admin_password'

portainer_ssl_key='/etc/portainer/certs/portainer.key'
portainer_ssl_cert='/etc/portainer/certs/portainer.crt'

run_uid_gid='0:0'





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

log_warn 'if $PORTAINER_PASSWORD is not set, a random password will be generated:'
log_warn "export PORTAINER_PASSWORD='<password>'"

if [ ! -S "$portainer_docker_socket_file" ]; then
    log_error 'docker socket not found, quit now'
    exit 1
fi

if [ "${#portainer_admin_password}" -lt 12 ]; then
    log_error 'portainer admin password is too short, at least 12 characters are required, quit now'
    log_error "export PORTAINER_PASSWORD='<password>'"
    exit 1
fi

docker inspect "$portainer_container_name" >'/dev/null' 2>&1
if [ $? -eq 0 ]; then
    log_info 'portainer container already exists, quit now'
    exit 0
fi

volume_exists=0
docker volume inspect "$portainer_volume_name" >'/dev/null' 2>&1
if [ $? -eq 0 ]; then
    volume_exists=1
fi
if [ $volume_exists -eq 0 ]; then
    docker volume create "$portainer_volume_name"
    {
        if_error_then_exit 'portainer volume create failed, quit now'
    }
    log_info "portainer volume created: ${portainer_volume_name}"
else
    log_info "portainer volume reuse: ${portainer_volume_name}"
fi

prepare_dir "$(dirname "$portainer_admin_password_file")" "$run_uid_gid"
{
    if_error_then_exit 'portainer secrets dir create failed, quit now'
}

update_file "$portainer_admin_password_file" "$portainer_admin_password" "$run_uid_gid" '600'
{
    if_error_then_exit 'portainer password file create failed, quit now'
}

generate_ssl_cert 'Portainer' "$portainer_ssl_key" "$portainer_ssl_cert" "$run_uid_gid"
{
    if_error_then_exit 'portainer ssl cert generate failed, quit now'
}

docker pull "$portainer_image"
{
    if_error_then_exit 'portainer image pull failed, quit now'
}

docker run -d \
    --user "$run_uid_gid" \
    --name "$portainer_container_name" \
    --restart unless-stopped \
    -p "$portainer_server_port:9443" \
    -v "$portainer_docker_socket_file:/var/run/docker.sock" \
    -v "$portainer_volume_name:/data" \
    -v "$portainer_ssl_cert:/certs/portainer.crt:ro" \
    -v "$portainer_ssl_key:/certs/portainer.key:ro" \
    -v "$portainer_admin_password_file:/run/secrets/portainer_admin_password:ro" \
    "$portainer_image" \
    --tlscert /certs/portainer.crt \
    --tlskey /certs/portainer.key \
    --admin-password-file /run/secrets/portainer_admin_password
{
    if_error_then_exit 'portainer container start failed, quit now'
}

portainer_server_name=$(hostname)
portainer_server_ip=$(get_system_ip)

log_important "portainer server name: ${portainer_server_name}"
log_important "portainer server ip: ${portainer_server_ip}"
log_important "portainer server port: ${portainer_server_port}"

log_important "portainer dashboard url: https://${portainer_server_ip}:${portainer_server_port}"
log_important "portainer user: ${portainer_admin_user}"
log_important "portainer password: ${portainer_admin_password}"

log_important "portainer volume: ${portainer_volume_name}"
log_important "portainer ssl cert: ${portainer_ssl_cert}"
log_important "portainer ssl key: ${portainer_ssl_key}"





# ———————————————————————— Start ————————————————————————
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
log_info "docker logs $portainer_container_name:" && docker logs "$portainer_container_name"

show_tcp_listening
