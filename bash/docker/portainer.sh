#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/portainer.sh' | bash

# export PORTAINER_PASSWORD="<password>"
# docker rm -f portainer && docker volume rm -f portainer_data

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

portainer_sslkey='/etc/portainer/certs/portainer.key'
portainer_sslcert='/etc/portainer/certs/portainer.crt'

run_uid_gid='0:0'



function portainer_gen_ssl_cert(){
    mkdir -p $(dirname "$portainer_sslkey")
    openssl req -newkey rsa:4096 -nodes -keyout "$portainer_sslkey" -x509 -days 365000 -out "$portainer_sslcert" -subj '/CN=Portainer'
    {
        if_error_then_exit 'portainer_gen_ssl_cert failed, quit now'
    }

    chown "$run_uid_gid" "$portainer_sslkey" "$portainer_sslcert"
    chmod 600 "$portainer_sslkey"
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

log_warn 'if $PORTAINER_PASSWORD is not set, a random password will be generated:'
log_warn 'export PORTAINER_PASSWORD="<password>"'

if [ ! -S "$portainer_docker_socket_file" ]; then
    log_error 'docker socket not found, quit now'
    exit 1
fi

docker inspect "$portainer_container_name" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_info 'portainer container already exists, quit now'
    exit 0
fi

volume_exists=0
docker volume inspect "$portainer_volume_name" > /dev/null 2>&1
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

docker pull "$portainer_image"
{
    if_error_then_exit 'portainer image pull failed, quit now'
}

portainer_gen_ssl_cert

portainer_admin_password_hash=$(htpasswd -nbB "$portainer_admin_user" "$portainer_admin_password" | cut -d: -f2)
if [ -z "$portainer_admin_password_hash" ]; then
    log_error 'portainer admin password hash generate failed, quit now'
    exit 1
fi

docker run -d \
    --user "$run_uid_gid" \
    --name "$portainer_container_name" \
    --restart unless-stopped \
    -p "$portainer_server_port:9443" \
    -v "$portainer_docker_socket_file:/var/run/docker.sock" \
    -v "$portainer_volume_name:/data" \
    -v "$portainer_sslcert:/certs/portainer.crt:ro" \
    -v "$portainer_sslkey:/certs/portainer.key:ro" \
    "$portainer_image" \
    --sslcert /certs/portainer.crt \
    --sslkey /certs/portainer.key \
    --admin-password "$portainer_admin_password_hash"
{
    if_error_then_exit 'portainer container start failed, quit now'
}

portainer_server_name=$(hostname)
portainer_server_ip=$(hostname -I | awk '{print $1}')

log_attention "portainer server name: ${portainer_server_name}"
log_attention "portainer server ip: ${portainer_server_ip}"
log_attention "portainer server port: ${portainer_server_port}"

log_attention "portainer dashboard url: https://${portainer_server_ip}:${portainer_server_port}"
log_attention "portainer user: ${portainer_admin_user}"
log_attention "portainer password: ${portainer_admin_password}"

log_attention "portainer volume: ${portainer_volume_name}"
log_attention "portainer ssl cert: ${portainer_sslcert}"
log_attention "portainer ssl key: ${portainer_sslkey}"





# ———————————————————————— Start ————————————————————————
show_tcp_listening

log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a

log_info "docker logs $portainer_container_name:" && docker logs "$portainer_container_name"
