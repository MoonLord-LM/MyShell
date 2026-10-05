#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/cockpit.sh' | bash

# apt remove -y cockpit-bridge && rm -rf '/etc/cockpit/'

# Cockpit
# https://github.com/cockpit-project/cockpit





# ———————————————————————— Config ————————————————————————
cockpit_conf_file='/etc/cockpit/cockpit.conf'
cockpit_socket_conf_file='/etc/systemd/system/cockpit.socket.d/override.conf'
cockpit_ssl_key='/etc/cockpit/ws-certs.d/1-self-signed.key'
cockpit_ssl_cert='/etc/cockpit/ws-certs.d/1-self-signed.cert'

cockpit_server_port=19190
cockpit_allow_groups='root'

cockpit_components='cockpit cockpit-doc cockpit-machines'

cockpit_idle_timeout=1800
cockpit_allow_multi_host=false

run_uid_gid='root:root'

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
check_command_exist 'cockpit-bridge'
if [ $? -eq 0 ]; then
    log_info 'cockpit already installed, quit now'
    exit 0
fi

check_system_is_ubuntu || check_system_is_debian
{
    if_error_then_exit 'cockpit install failed, unknown system'
}

codename=$(get_system_version_codename)
{
    if_error_then_exit 'get codename failed, quit now'
}

for cockpit_component in $cockpit_components; do
    install_software "$cockpit_component"
    {
        if_error_then_exit "cockpit component install failed: $cockpit_component, quit now"
    }
done

cockpit-bridge --version
{
    if_error_then_exit 'cockpit version check failed, quit now'
}

update_file "${cockpit_conf_file}" "$(cockpit_config_conf)"
{
    if_error_then_exit 'cockpit config file write failed, quit now'
}
update_file "${cockpit_socket_conf_file}" "$(cockpit_socket_override)"
{
    if_error_then_exit 'cockpit socket config file write failed, quit now'
}
systemctl daemon-reload

echo > /etc/cockpit/disallowed-users

generate_ssl_cert 'Cockpit' "$cockpit_ssl_key" "$cockpit_ssl_cert" "$run_uid_gid"
{
    if_error_then_exit 'cockpit ssl certificate generation failed, quit now'
}

cockpit_server_ip=$(get_system_ip)
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
