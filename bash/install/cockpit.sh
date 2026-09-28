#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/cockpit.sh' | bash

# apt remove -y cockpit-bridge
# rm -rf '/etc/cockpit/'

# Cockpit
# https://github.com/cockpit-project/cockpit





# ———————————————————————— Config ————————————————————————
cockpit_apt_source_file='/etc/apt/sources.list.d/cockpit-backports.list'
cockpit_conf_file='/etc/cockpit/cockpit.conf'
cockpit_socket_conf_file='/etc/systemd/system/cockpit.socket.d/override.conf'
cockpit_ssl_key='/etc/cockpit/ws-certs.d/0-self-signed.key'
cockpit_ssl_cert='/etc/cockpit/ws-certs.d/0-self-signed.cert'

cockpit_server_port=19190
cockpit_allow_groups='root'

cockpit_idle_timeout=1800
cockpit_allow_multi_host=false

function cockpit_config_conf(){
    cat <<EOF
[WebService]
AllowUnencrypted = false
IdleTimeout = ${cockpit_idle_timeout}
AllowMultiHost = ${cockpit_allow_multi_host}

[Session]
AllowGroups = ${cockpit_allow_groups}
EOF
}

function cockpit_socket_override(){
    cat <<EOF
[Socket]
ListenStream=
ListenStream=[::]:${cockpit_server_port}
EOF
}

function cockpit_gen_ssl_cert(){
    mkdir -p $(dirname "$cockpit_ssl_key")
    openssl req -newkey rsa:4096 -nodes -keyout "$cockpit_ssl_key" -x509 -days 365000 -out "$cockpit_ssl_cert" -subj '/CN=Cockpit'
    if [ $? -ne 0 ]; then
        log_error 'cockpit_gen_ssl_cert failed, quit now'
        exit 1
    fi

    chown root:root "$cockpit_ssl_key"
    chmod 600 "$cockpit_ssl_key"
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist 'cockpit-bridge'
if [ $? -eq 0 ]; then
    log_info 'cockpit already installed, quit now'
    exit 0
fi

if ! check_system_is_ubuntu && ! check_system_is_debian; then
    log_error 'cockpit install failed, unknown system'
    exit 1
fi

codename=$(get_system_version_codename)
if [ -z "${codename}" ]; then
    log_error 'get codename failed, quit now'
    exit 1
fi

show_software 'cockpit-bridge'
if [ $? -ne 0 ]; then
    if check_system_is_debian; then
        echo "deb http://deb.debian.org/debian ${codename}-backports main" > "$cockpit_apt_source_file"
    elif check_system_is_ubuntu; then
        echo "deb http://archive.ubuntu.com/ubuntu ${codename}-backports main restricted universe multiverse" > "$cockpit_apt_source_file"
    fi
    update_software
    apt install -t "${codename}-backports" -y cockpit cockpit-storaged cockpit-networkmanager cockpit-files cockpit-machines cockpit-sosreport
fi

show_software 'cockpit-bridge'
if [ $? -ne 0 ]; then
    log_error 'cockpit install failed, quit now'
    exit 1
fi

cockpit-bridge --version
if [ $? -ne 0 ]; then
    log_error 'cockpit version check failed, quit now'
    exit 1
fi

mkdir -p $(dirname "${cockpit_conf_file}")
backup_file "${cockpit_conf_file}"
cockpit_config_conf > "${cockpit_conf_file}"

mkdir -p $(dirname "${cockpit_socket_conf_file}")
backup_file "${cockpit_socket_conf_file}"
cockpit_socket_override > "${cockpit_socket_conf_file}"
systemctl daemon-reload

echo > /etc/cockpit/disallowed-users

cockpit_gen_ssl_cert

cockpit_server_ip=$(hostname -I | awk '{print $1}')
log_attention "cockpit server ip: ${cockpit_server_ip}"
log_attention "cockpit server port: ${cockpit_server_port}"
log_attention "cockpit dashboard url: https://${cockpit_server_ip}:${cockpit_server_port}"
log_attention "cockpit allow login group: ${cockpit_allow_groups}"

log_attention "cockpit config: ${cockpit_conf_file}"
log_attention "cockpit socket config: ${cockpit_socket_conf_file}"
log_attention "cockpit ssl key: ${cockpit_ssl_key}"
log_attention "cockpit ssl cert: ${cockpit_ssl_cert}"





# ———————————————————————— Start ————————————————————————
systemctl restart 'cockpit.socket'
systemctl enable 'cockpit.socket'
systemctl status --no-pager 'cockpit.socket'

show_tcp_listening
