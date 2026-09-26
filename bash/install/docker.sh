#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash

# Docker
# https://github.com/docker





# ———————————————————————— Config ————————————————————————
docker_apt_repo_url='https://download.docker.com/linux'
docker_gpg_key_file='/etc/apt/keyrings/docker.gpg'
docker_apt_source_file='/etc/apt/sources.list.d/docker.list'

docker_components='docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist 'docker'
if [ $? -eq 0 ]; then
    log_info 'docker already installed, quit now'
    exit 0
fi

if check_system_is_ubuntu; then
    docker_repo_url="$docker_apt_repo_url/ubuntu"
elif check_system_is_debian; then
    docker_repo_url="$docker_apt_repo_url/debian"
else
    log_error 'docker install failed, unknown system'
    exit 1
fi

mkdir -p "$(dirname "$docker_gpg_key_file")"
wget -O- --timeout=120 --no-cache "${docker_repo_url}/gpg" | gpg --dearmor --yes -o "$docker_gpg_key_file"
if [ $? -ne 0 ]; then
    log_error 'docker gpg key download failed, quit now'
    exit 1
fi

codename=$(get_system_version_codename)
system_arch="$(dpkg --print-architecture)"
echo "deb [arch=$system_arch signed-by=$docker_gpg_key_file] $docker_repo_url $codename stable" > "$docker_apt_source_file"
if [ $? -ne 0 ]; then
    log_error 'docker apt source setup failed, quit now'
    exit 1
fi

for component in $docker_components; do
    install_software "$component"
    if [ $? -ne 0 ]; then
        log_error "docker component install failed: $component, quit now"
        exit 1
    fi
done

docker version
if [ $? -ne 0 ]; then
    log_error 'docker install failed, quit now'
    exit 1
fi

docker compose version
if [ $? -ne 0 ]; then
    log_error 'docker compose install failed, quit now'
    exit 1
fi





# ———————————————————————— Start ————————————————————————
systemctl restart 'docker'
systemctl enable 'docker'
systemctl status --no-pager 'docker'

show_tcp_listening

docker run 'hello-world'
if [ $? -ne 0 ]; then
    log_error 'docker test failed, quit now'
    exit 1
fi
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a

docker image rm 'hello-world'
docker rm $(docker ps -a -q --filter ancestor=hello-world)
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
