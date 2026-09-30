#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/portainer.sh' | bash

# docker rm -f portainer && docker volume rm portainer_data

# Portainer CE
# https://github.com/portainer/portainer
# https://docs.portainer.io/start/install-ce/server/docker/linux





# ———————————————————————— Config ————————————————————————
portainer_container_name='portainer'
portainer_image='portainer/portainer-ce:latest'
portainer_volume_name='portainer_data'
portainer_server_port=19443
portainer_docker_socket_file='/var/run/docker.sock'

run_uid_gid='root:root'



function generate_portainer_warning(){
    cat <<EOF
Portainer CE is installed.
Open https://${portainer_server_ip}:${portainer_server_port} in your browser to finish the initial setup.
You will be asked to create an admin user, then choose the "Local" environment to manage the host.
EOF
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

if [ ! -S "$portainer_docker_socket_file" ]; then
    log_error 'docker socket not found, quit now'
    exit 1
fi

docker inspect "$portainer_container_name" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_info 'portainer container already exists, quit now'
    exit 0
fi

docker volume create "$portainer_volume_name"
{
    if_error_then_exit 'portainer volume create failed, quit now'
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
    "$portainer_image"
{
    if_error_then_exit 'portainer container start failed, quit now'
}

portainer_server_name=$(hostname)
portainer_server_ip=$(hostname -I | awk '{print $1}')

log_attention "portainer server name: ${portainer_server_name}"
log_attention "portainer server ip: ${portainer_server_ip}"
log_attention "portainer web https port: ${portainer_server_port}"
log_attention "portainer volume: ${portainer_volume_name}"

portainer_web_url="https://${portainer_server_ip}:${portainer_server_port}"
log_success "portainer web url: ${portainer_web_url}"

echo
log_attention "$(generate_portainer_warning)"





# ———————————————————————— Start ————————————————————————
show_tcp_listening

log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a

log_info "docker logs $portainer_container_name:" && docker logs "$portainer_container_name"
