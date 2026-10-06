#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/docker.sh' | bash

# apt remove -y docker-ce-cli

# Docker
# https://github.com/docker





# ———————————————————————— Config ————————————————————————
docker_apt_repo_url='https://download.docker.com/linux'
docker_gpg_key_file='/etc/apt/keyrings/docker.gpg'
docker_apt_source_file='/etc/apt/sources.list.d/docker.list'

docker_components='docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'

run_uid_gid='root:root'





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
if [ $? -eq 0 ]; then
    log_info 'docker already installed, quit now'
    exit 0
fi

check_system_is_ubuntu
if [ $? -eq 0 ]; then
    docker_repo_url="$docker_apt_repo_url/ubuntu"
else
    check_system_is_debian
    if [ $? -eq 0 ]; then
        docker_repo_url="$docker_apt_repo_url/debian"
    else
        log_error 'docker install failed, unknown system'
        exit 1
    fi
fi

mkdir -p "$(dirname "$docker_gpg_key_file")"

tmp_file="/tmp/docker-gpg-key_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.asc"
wget -O "$tmp_file" --timeout=120 --no-cache "${docker_repo_url}/gpg"
{
    if_error_then_exit 'docker gpg key download failed, quit now'
}

gpg --dearmor --yes -o "$docker_gpg_key_file" "$tmp_file"
{
    if_error_then_exit 'docker gpg key dearmor failed, quit now'
}
rm -f "$tmp_file"

codename=$(get_system_version_codename)
{
    if_error_then_exit 'docker get_system_version_codename failed, quit now'
}

system_arch="$(dpkg --print-architecture)"
update_file "$docker_apt_source_file" "deb [arch=$system_arch signed-by=$docker_gpg_key_file] $docker_repo_url $codename stable"
{
    if_error_then_exit 'docker apt source setup failed, quit now'
}

for component in $docker_components; do
    install_software "$component"
    {
        if_error_then_exit "docker component install failed: $component, quit now"
    }
done

docker version
{
    if_error_then_exit 'docker install failed, quit now'
}

docker compose version
{
    if_error_then_exit 'docker compose install failed, quit now'
}





# ———————————————————————— Start ————————————————————————
systemctl restart 'docker'
systemctl enable 'docker'
systemctl status --no-pager 'docker'

show_tcp_listening

docker run 'hello-world'
{
    if_error_then_exit 'docker test failed, quit now'
}
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a

hello_world_container_ids=$(docker ps -a -q --filter ancestor=hello-world)
if [ "$hello_world_container_ids" != '' ]; then
    docker rm -f $hello_world_container_ids
fi
docker rmi 'hello-world'
log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
