#!/bin/bash

# source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )

# MyShell
# https://github.com/MoonLord-LM/MyShell





# 检查函数入参（最多9个）必须全都不为空字符串，否则报错
function check_parameter(){
    if [ "${FUNCNAME[1]}" != '' ]; then
        local current_function="${FUNCNAME[1]}"
    else
        local current_function="${FUNCNAME[0]}"
    fi
    local color_red='1;31'
    for i in $(seq 1 "$#"); do
        if [ "${!i}" == '' ]; then
            if [ -t 2 ]; then
                printf '\033[s%m%s: parameter [ ${!i} ] is empty\033[0m\n' "$color_red" "$current_function" >&2
            else
                printf '%s: parameter [ ${!i} ] is empty\n' "$current_function" >&2
            fi
            return 1
        fi
    done
}



# 输出日志（$1 颜色代码；$2 日志内容）
function my_log(){
    check_parameter "$1" || return 1
    check_parameter "$2" || return 1
    local color_code="$1"
    local message="$2"

    if [ -t 2 ]; then
        printf '\033[%sm%s\033[0m\n' "$color_code" "$message" >&2
    else
        printf '%s\n' "$message" >&2
    fi
}
# 输出红色的错误信息（$1）
function log_error(){
    check_parameter "$1" || return 1
    my_log '1;31' "$1"
}
# 输出绿色的成功信息（$1）
function log_success(){
    check_parameter "$1" || return 1
    my_log '1;32' "$1"
}
# 输出黄色的警告信息（$1）
function log_warn(){
    check_parameter "$1" || return 1
    my_log '1;33' "$1"
}
# 输出深蓝色的提示信息（$1）
function log_info(){
    check_parameter "$1" || return 1
    my_log '1;34' "$1"
}
# 输出紫色的提示信息（$1）
function log_attention(){
    check_parameter "$1" || return 1
    my_log '1;35' "$1"
}
# 输出浅蓝色的提示信息（$1）
function log_notice(){
    check_parameter "$1" || return 1
    my_log '1;36' "$1"
}



# 如果上一个命令执行异常，那么结束运行，并输出红色的错误信息（$1）
function if_error_then_exit() {
    if [ $? -ne 0 ]; then
        check_parameter "$1" || return 1
        log_error "$1"
        exit 1
    fi
}



# 重设 root 密码为 256 bit 随机数，并显示新密码
function reset_root_password(){
    log_info 'reset_root_password begin'

    local root_password=''
    root_password=$(head -c 32 '/dev/urandom' | base64 -w 0)
    if [ "$root_password" == '' ]; then
        log_error 'reset_root_password failed, generate random password error'
        return 1
    fi

    echo "root:${root_password}" | chpasswd
    if [ $? -ne 0 ]; then
        log_error 'reset_root_password failed, chpasswd error'
        return 1
    fi

    log_attention "reset_root_password ok, new root password is: ${root_password}"
}



# 获取系统的名称
function get_system_name(){
    local os_release_file='/etc/os-release'
    if [ -f "$os_release_file" ]; then
        # 读取 PRETTY_NAME 的值，并去掉可能存在的首尾双引号
        local name=$(grep '^PRETTY_NAME=' "$os_release_file" | head -n 1 | sed -e 's/^PRETTY_NAME=//' -e 's/^"//' -e 's/"$//')
        if [ "$name" != '' ]; then
            echo "$name"
            return 0
        fi
    fi
    log_error 'get_system_name failed, unknown system'
    return 1
}
# 获取系统的版本代号
function get_system_version_codename(){
    local os_release_file='/etc/os-release'
    if [ -f "$os_release_file" ]; then
        # 读取 VERSION_CODENAME 的值，并去掉可能存在的首尾双引号
        local codename=$(grep '^VERSION_CODENAME=' "$os_release_file" | head -n 1 | sed -e 's/^VERSION_CODENAME=//' -e 's/^"//' -e 's/"$//')
        if [ "$codename" != '' ]; then
            echo "$codename"
            return 0
        fi
    fi
    log_error 'get_system_version_codename failed, unknown system'
    return 1
}
# 判断系统是否是 Ubuntu
function check_system_is_ubuntu(){
    local name=$(get_system_name)
    echo "$name" | grep 'Ubuntu' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info 'check_system_is_ubuntu: false'
        return 1
    fi
    log_info "check_system_is_ubuntu: $name"
}
# 判断系统是否是 Debian
function check_system_is_debian(){
    local name=$(get_system_name)
    echo "$name" | grep 'Debian' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info 'check_system_is_debian: false'
        return 1
    fi
    log_info "check_system_is_debian: $name"
}
# 获取系统的 IP
function get_system_ip(){
    local ip=$(hostname -I 2>'/dev/null' | awk '{print $1}')
    if [ "$ip" != '' ]; then
        echo "$ip"
        return 0
    fi
    log_error 'get_system_ip failed'
    echo '127.0.0.1'
    return 1
}



# 判断指定命令（$1）是否存在
function check_command_exist(){
    check_parameter "$1" || return 1
    local cmd="$1"

    command -v "$cmd" > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info "check_command_exist: \"$cmd\" does not exist"
        return 1
    fi

    local cmd_file_path="$(command -v "$cmd")"
    local pkg_info="$(dpkg -S "$cmd_file_path" 2>'/dev/null')"

    if [ "$pkg_info" != '' ] ; then
        log_info "check_command_exist: \"$cmd\" exists in \"$pkg_info\""
    else
        log_info "check_command_exist: \"$cmd\" exists in \"$cmd_file_path\""
    fi
}
# 更新软件（保守，允许安装新依赖，不删除已安装的软件）
function update_software(){
    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error 'update_software failed, unknown system'
        return 1
    fi

    dpkg --configure -a
    if [ $? -ne 0 ]; then
        log_error 'dpkg configure failed'
        return 1
    fi
    apt update -y
    if [ $? -ne 0 ]; then
        log_error 'apt update failed'
        return 1
    fi
    apt upgrade -y
    if [ $? -ne 0 ]; then
        log_error 'apt upgrade failed'
        return 1
    fi
    apt autoremove -y
    if [ $? -ne 0 ]; then
        log_error 'apt autoremove failed'
        return 1
    fi
}
# 更新软件（激进，允许安装新依赖，允许删除已安装的软件）
function update_software_aggressive(){
    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error 'update_software_aggressive failed, unknown system'
        return 1
    fi

    update_software
    if [ $? -ne 0 ]; then
        log_error 'update_software_aggressive - update_software failed'
        return 1
    fi
    apt full-upgrade -y
    if [ $? -ne 0 ]; then
        log_error 'apt full-upgrade failed'
        return 1
    fi
    apt autoremove --purge -y
    if [ $? -ne 0 ]; then
        log_error 'apt autoremove purge failed'
        return 1
    fi
}
# 安装指定名称（$1）的软件
function install_software(){
    check_parameter "$1" || return 1
    local software="$1"

    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error "install_software failed, unknown system"
        return 1
    fi

    dpkg-query -W -f='${Status}' "$software" 2> '/dev/null' | grep -q 'install ok installed'
    if [ $? -ne 0 ]; then
        apt update -y
        if [ $? -ne 0 ]; then
            log_error "install_software failed, apt update error"
            return 1
        fi
        apt install -y "$software"
        if [ $? -ne 0 ]; then
            log_error "install_software failed, \"$software\" install error"
            return 1
        else
            log_info "install_software end, \"$software\" install ok"
        fi
    else
        log_info "install_software skip, \"$software\" is already installed"
    fi
}
# 卸载指定名称（$1）的软件
function remove_software(){
    check_parameter "$1" || return 1
    local software="$1"

    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error "remove_software failed, unknown system"
        return 1
    fi

    dpkg-query -W -f='${Status}' "$software" 2> '/dev/null' | grep -q 'install ok installed'
    if [ $? -ne 0 ]; then
        log_info "remove_software skip, \"$software\" is already removed"
        return 0
    fi

    apt remove -y "$software"
    if [ $? -ne 0 ]; then
        log_error "remove_software failed, \"$software\" apt remove error"
        return 1
    fi
    apt autoremove -y
    if [ $? -ne 0 ]; then
        log_error "remove_software failed, \"$software\" apt autoremove error"
        return 1
    fi
    dpkg --purge "$software"
    if [ $? -ne 0 ]; then
        log_error "remove_software failed, \"$software\" dpkg purge error"
        return 1
    fi
    log_info "remove_software end, \"$software\" remove ok"
}
# 准备常用的命令
function prepare_common_command(){
    check_command_exist 'netstat' || install_software 'net-tools'
    check_command_exist 'curl' || install_software 'curl'

    check_command_exist 'openssl' || install_software 'openssl'
    check_command_exist 'htpasswd' || install_software 'apache2-utils'

    check_command_exist 'python3' || install_software 'python3'
    check_command_exist 'java' || install_software 'openjdk'

    check_command_exist 'git' || install_software 'git'
    check_command_exist 'mvn' || install_software 'maven'

    check_command_exist 'make' || install_software 'make'
    check_command_exist 'cmake' || install_software 'cmake'
    check_command_exist 'gcc' || install_software 'gcc'
    check_command_exist 'g++' || install_software 'g++'
}
# 查看系统已安装的程序和版本
function show_software_list(){
    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error "show_software_list failed, unknown system"
        return 1
    fi

    log_info "dpkg-query -W -f='\${Package} \${Version}' | grep 'install ok installed'"
    dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2> '/dev/null' | grep 'install ok installed' | awk '{print $1" "$2}'
}
# 搜索已安装的软件（$1 为关键字，模糊匹配包名和描述等），显示名称和版本
function search_software(){
    check_parameter "$1" || return 1
    local keyword="$1"

    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error "search_software failed, unknown system"
        return 1
    fi

    local result=''
    result=$(dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2> '/dev/null' \
        | grep 'install ok installed' | awk '{print $1" "$2}' | grep -i "$keyword")
    if [ "$result" == '' ]; then
        # 包名没匹配到时，再按软件描述搜索
        result=$(dpkg-query -W -f='${binary:Package}|${Version}|${Status}|${Description}\n' 2> '/dev/null' \
            | grep 'install ok installed' | grep -i "$keyword" | awk -F'|' '{print $1" "$2}')
    fi
    if [ "$result" == '' ]; then
        log_info "search_software: no software found by keyword \"$keyword\""
        return 1
    fi
    log_info "search_software: search \"$keyword\""
    echo "$result"
}
# 系统版本升级（例如，Debian bookworm → trixie 和 Ubuntu noble → resolute）
function update_system(){
    check_system_is_ubuntu || check_system_is_debian
    if [ $? -ne 0 ]; then
        log_error 'update_system failed, unknown system'
        return 1
    fi

    local codename=''
    codename=$(get_system_version_codename)
    if [ $? -ne 0 ]; then
        log_error 'update_system failed, cannot get system codename'
        return 1
    fi

    local target_codename=''
    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        if [[ "${codename}" == 'trixie' ]]; then
            log_success "update_system: no need to update, current: $(get_system_name) / ${codename}"
            return 0
        elif [[ "${codename}" == 'bookworm' ]]; then
            target_codename='trixie'
        else
            log_error "update_system: Debian only support upgrade from bookworm, current: ${codename}"
            return 1
        fi
    else
        if [[ "${codename}" == 'resolute' ]]; then
            log_success "update_system: no need to update, current: $(get_system_name) / ${codename}"
            return 0
        elif [[ "${codename}" == 'noble' ]]; then
            target_codename='resolute'
        else
            log_error "update_system: Ubuntu only support upgrade from noble, current: ${codename}"
            return 1
        fi
    fi
    log_warn "update_system: ${codename} → ${target_codename}"

    local sources_list=''
    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        sources_list='/etc/apt/sources.list'
    else
        sources_list='/etc/apt/sources.list.d/ubuntu.sources'
    fi

    backup_file "$sources_list"
    if [ $? -ne 0 ]; then
        log_error 'update_system failed, backup_file failed'
        return 1
    fi
    sed -i "s/${codename}/${target_codename}/g" "$sources_list"

    update_software_aggressive
    if [ $? -ne 0 ]; then
        log_error 'update_system failed, update_software_aggressive failed'
        return 1
    fi
}



# 准备文件夹（$1 目录路径；$2 可选参数：设置归属用户；$3 可选参数：设置目录权限）
function prepare_dir(){
    check_parameter "$1" || return 1
    local target_dir="$1"
    local target_user="$2"
    local target_mode="$3"

    mkdir -p "$target_dir"
    if [ $? -ne 0 ]; then
        log_error "prepare_dir failed, mkdir \"$target_dir\" error"
        return 1
    fi

    if [ "$target_user" != '' ]; then
        chown "$target_user" "$target_dir"
        if [ $? -ne 0 ]; then
            log_error "prepare_dir failed, chown \"$target_dir\" to \"$target_user\" error"
            return 1
        fi
    fi

    if [ "$target_mode" != '' ]; then
        chmod "$target_mode" "$target_dir"
        if [ $? -ne 0 ]; then
            log_error "prepare_dir failed, chmod $target_mode \"$target_dir\" error"
            return 1
        fi
    fi

    log_info "prepare_dir ok, \"$target_dir\" is ready"
}
# 备份文件（把指定路径 $1 的文件，保存到 [ - 时间.bak] 后缀的文件中）
function backup_file(){
    check_parameter "$1" || return 1
    local source_file="$1"

    local current_time=$(date "+%Y%m%d%H%M%S%z")
    local backup_new_file="$source_file - $current_time.bak"

    if [ ! -f "$source_file" ]; then
        log_attention "file \"$source_file\" is not found"
        return 1
    fi
    if [ -f "$backup_new_file" ]; then
        log_error "file \"$backup_new_file\" already exists"
        return 1
    fi

    \cp -f "$source_file" "$backup_new_file"
    if [ ! -f "$backup_new_file" ]; then
        log_error "file \"$backup_new_file\" copy failed"
        return 1
    fi

    log_info "backup_file ok, from \"$source_file\" to \"$backup_new_file\""
}
# 更新文件内容（$1 文件路径；$2 文件内容；$3 可选参数：设置归属用户；$4 可选参数：设置文件权限）
function update_file(){
    check_parameter "$1" || return 1
    check_parameter "$2" || return 1
    local target_file="$1"
    local target_content="$2"
    local target_user="$3"
    local target_file_mode="$4"

    mkdir -p "$(dirname "$target_file")"
    if [ $? -ne 0 ]; then
        log_error "update_file failed, mkdir \"$(dirname "$target_file")\" error"
        return 1
    fi

    if [ -f "$target_file" ]; then
        local old_content=$(cat "$target_file")
        if [ "$old_content" == "$target_content" ]; then
            log_info "update_file skip, \"$target_file\" is not changed"
            return 0
        fi
        backup_file "$target_file"
        if [ $? -ne 0 ]; then
            log_error "update_file failed, backup_file \"$target_file\" error"
            return 1
        fi
    fi

    printf '%s' "$target_content" > "$target_file"
    if [ $? -ne 0 ]; then
        log_error "update_file failed, write file \"$target_file\" error"
        return 1
    fi

    if [ "$target_user" != '' ]; then
        chown "$target_user" "$target_file"
        if [ $? -ne 0 ]; then
            log_error "update_file failed, chown \"$target_file\" to \"$target_user\" error"
            return 1
        fi
    fi

    if [ "$target_file_mode" != '' ]; then
        chmod "$target_file_mode" "$target_file"
        if [ $? -ne 0 ]; then
            log_error "update_file failed, chmod $target_file_mode \"$target_file\" error"
            return 1
        fi
    fi

    log_info "update_file ok, \"$target_file\" is updated"
}
# 生成 SSL 证书文件（$1 证书名称；$2 私钥文件路径；$3 证书文件路径；$4 可选参数：设置归属用户）
function generate_ssl_cert(){
    check_parameter "$1" || return 1
    check_parameter "$2" || return 1
    check_parameter "$3" || return 1
    local ssl_subject_name="$1"
    local ssl_key_file="$2"
    local ssl_cert_file="$3"
    local target_user="$4"

    mkdir -p "$(dirname "$ssl_key_file")"
    if [ $? -ne 0 ]; then
        log_error "generate_ssl_cert failed, mkdir \"$(dirname "$ssl_key_file")\" error"
        return 1
    fi
    mkdir -p "$(dirname "$ssl_cert_file")"
    if [ $? -ne 0 ]; then
        log_error "generate_ssl_cert failed, mkdir \"$(dirname "$ssl_cert_file")\" error"
        return 1
    fi

    openssl req \
        -newkey rsa:4096 -nodes -keyout "$ssl_key_file" \
        -x509 -days 365000 -out "$ssl_cert_file" \
        -subj "/CN=$ssl_subject_name"
    if [ $? -ne 0 ]; then
        log_error "generate_ssl_cert failed"
        return 1
    fi

    if [ "$target_user" != '' ]; then
        chown "$target_user" "$ssl_key_file"
        if [ $? -ne 0 ]; then
            log_error "generate_ssl_cert failed, chown \"$ssl_key_file\" to \"$target_user\" error"
            return 1
        fi
        chown "$target_user" "$ssl_cert_file"
        if [ $? -ne 0 ]; then
            log_error "generate_ssl_cert failed, chown \"$ssl_cert_file\" to \"$target_user\" error"
            return 1
        fi
    fi
    
    chmod 600 "$ssl_key_file"
    if [ $? -ne 0 ]; then
        log_error "generate_ssl_cert failed, chmod 600 \"$ssl_key_file\" error"
        return 1
    fi
}



# 设置系统时区为中国时区（Asia/Shanghai GMT+08:00）
function set_timezone_china(){
    local old_time=$(date "+%Y-%m-%d %H:%M:%S %z")
    log_info "set_timezone_china begin, old time is \"$old_time\""

    check_command_exist 'timedatectl'
    if [ $? -ne 0 ]; then
        log_error 'set_timezone_china failed, timedatectl does not exist'
        return 1
    fi
    timedatectl set-timezone 'Asia/Shanghai'
    if [ $? -ne 0 ]; then
        log_error 'set_timezone_china failed, timedatectl set-timezone error'
        return 1
    fi

    local current_time=$(date "+%Y-%m-%d %H:%M:%S %z")
    log_info "set_timezone_china ok, current time is \"$current_time\""
    timedatectl
}
# 设置系统的 TCP 拥塞控制算法为 BBR
function set_tcp_congestion_control_bbr(){
    log_info 'set_tcp_congestion_control_bbr begin, show current value'
    sysctl 'net.ipv4.tcp_available_congestion_control'
    sysctl 'net.ipv4.tcp_congestion_control'
    sysctl 'net.core.default_qdisc'

    # 尝试加载 bbr 模块，并试探当前内核是否支持 bbr
    modprobe 'tcp_bbr' > '/dev/null' 2>&1
    sysctl -w 'net.ipv4.tcp_congestion_control=bbr' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_congestion_control_bbr failed, kernel does not support bbr'
        return 1
    fi

    local sysctl_conf_file='/etc/sysctl.conf'
    backup_file "$sysctl_conf_file"
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_congestion_control_bbr failed, backup sysctl.conf error'
        return 1
    fi

    sed -i '/net.ipv4.tcp_congestion_control/d' "$sysctl_conf_file"
    sed -i '/net.core.default_qdisc/d' "$sysctl_conf_file"

    echo 'net.ipv4.tcp_congestion_control = bbr' >> "$sysctl_conf_file"
    echo 'net.core.default_qdisc = fq' >> "$sysctl_conf_file"

    log_info 'set_tcp_congestion_control_bbr changed config, now reload'
    sysctl --load
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_congestion_control_bbr failed, sysctl --load error'
        return 1
    fi

    log_info 'set_tcp_congestion_control_bbr ok, show current value'
    sysctl 'net.ipv4.tcp_available_congestion_control'
    sysctl 'net.ipv4.tcp_congestion_control'
    sysctl 'net.core.default_qdisc'
}
# 设置系统的 TCP 收发缓冲区上限为 16MB
function set_tcp_network_buffer(){
    log_info 'set_tcp_network_buffer begin, show current value'
    sysctl 'net.core.rmem_max'
    sysctl 'net.core.wmem_max'
    sysctl 'net.ipv4.tcp_rmem'
    sysctl 'net.ipv4.tcp_wmem'

    local sysctl_conf_file='/etc/sysctl.conf'
    backup_file "$sysctl_conf_file"
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_network_buffer failed, backup sysctl.conf error'
        return 1
    fi

    sed -i '/net.core.rmem_max/d' "$sysctl_conf_file"
    sed -i '/net.core.wmem_max/d' "$sysctl_conf_file"
    sed -i '/net.ipv4.tcp_rmem/d' "$sysctl_conf_file"
    sed -i '/net.ipv4.tcp_wmem/d' "$sysctl_conf_file"

    echo 'net.core.rmem_max = 16777216' >> "$sysctl_conf_file"
    echo 'net.core.wmem_max = 16777216' >> "$sysctl_conf_file"
    echo 'net.ipv4.tcp_rmem = 4096 131072 16777216' >> "$sysctl_conf_file"
    echo 'net.ipv4.tcp_wmem = 4096 16384 16777216' >> "$sysctl_conf_file"

    log_info 'set_tcp_network_buffer changed config, now reload'
    sysctl --load
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_network_buffer failed, sysctl --load error'
        return 1
    fi

    log_info 'set_tcp_network_buffer ok, show current value'
    sysctl 'net.core.rmem_max'
    sysctl 'net.core.wmem_max'
    sysctl 'net.ipv4.tcp_rmem'
    sysctl 'net.ipv4.tcp_wmem'
}
# 设置系统的 TCP Fast Open 为 3（客户端+服务端）
function set_tcp_fastopen(){
    log_info 'set_tcp_fastopen begin, show current value'
    sysctl 'net.ipv4.tcp_fastopen'

    local sysctl_conf_file='/etc/sysctl.conf'
    backup_file "$sysctl_conf_file"
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_fastopen failed, backup sysctl.conf error'
        return 1
    fi

    sed -i '/net.ipv4.tcp_fastopen/d' "$sysctl_conf_file"

    echo 'net.ipv4.tcp_fastopen = 3' >> "$sysctl_conf_file"

    log_info 'set_tcp_fastopen changed config, now reload'
    sysctl --load
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_fastopen failed, sysctl --load error'
        return 1
    fi

    log_info 'set_tcp_fastopen ok, show current value'
    sysctl 'net.ipv4.tcp_fastopen'
}
# 尝试设置 /swapfile 文件为虚拟内存，以保证物理内存和虚拟内存的总量在 4GB 以上
function set_memory_swap_to_4GB(){
    local mem_size=$(free -m | awk '/^Mem:/{print $2}')
    local swap_size=$(free -m | awk '/^Swap:/{print $2}')
    log_info "set_memory_swap begin, physical memory is $mem_size MB, virtual memory is $swap_size MB"

    # 总量已满足 4GB 要求时直接返回
    if [ $(( mem_size + swap_size )) -ge 4096 ]; then
        log_info 'set_memory_swap end, memory is enough'
        return 0
    fi

    local need_size=$(( 4096 - mem_size ))
    if [ "$need_size" -le 0 ]; then
        log_info 'set_memory_swap end, memory is enough'
        return 0
    fi
    log_info "set_memory_swap need swap memory: $need_size MB"

    local swap_file='/swapfile'
    if awk '$2=="file"{print $1}' '/proc/swaps' | grep -q -F "$swap_file"; then
        log_info "set_memory_swap: \"$swap_file\" is active, try to swapoff it first"
        swapoff "$swap_file"
        if [ $? -ne 0 ]; then
            log_error 'set_memory_swap failed, swapoff old swap file error'
            return 1
        fi
    fi
    rm -f "$swap_file"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, remove old swap file error'
        return 1
    fi

    # 额外多分配 1MB
    dd if='/dev/zero' of="$swap_file" bs='1M' count="$(( need_size + 1 ))"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, dd error'
        return 1
    fi
    chmod 600 "$swap_file"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, chmod error'
        return 1
    fi
    mkswap "$swap_file"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, mkswap error'
        return 1
    fi
    swapon "$swap_file"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, swapon error'
        return 1
    fi

    local fstab_file='/etc/fstab'
    backup_file "$fstab_file"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, backup fstab error'
        return 1
    fi

    # 取 /proc/swaps 与 /etc/fstab 的并集
    local active_swap_files=$(awk '$2=="file"{print $1}' '/proc/swaps')
    local all_swap_files=$({
        echo "$active_swap_files"
        awk '!/^[[:space:]]*#/ && $3=="swap"{print $1}' "$fstab_file"
    } | sort -u)

    local swap_path=''
    while read -r swap_path; do
        if [ "$swap_path" == '' ] || [ "$swap_path" == "$swap_file" ] || [ ! -f "$swap_path" ]; then
            continue
        fi
        log_info "set_memory_swap remove old swap file: \"$swap_path\""
        echo "$active_swap_files" | grep -q -F -x "$swap_path"
        if [ $? -eq 0 ]; then
            swapoff "$swap_path" > '/dev/null' 2>&1
            if [ $? -ne 0 ]; then
                log_warn "set_memory_swap skip, swapoff \"$swap_path\" error, keep it"
                continue
            fi
        fi
        rm -f "$swap_path"
        if [ $? -ne 0 ]; then
            log_warn "set_memory_swap skip, remove \"$swap_path\" error, keep it"
            continue
        fi
        sed -i "\|^[[:space:]]*$swap_path[[:space:]]|d" "$fstab_file"
    done <<< "$all_swap_files"

    # 写入 /etc/fstab 以便重启后自动挂载
    grep -q -F "$swap_file" "$fstab_file"
    if [ $? -ne 0 ]; then
        echo "$swap_file swap swap defaults 0 0" >> "$fstab_file"
    fi
    swapon -a
    if [ $? -ne 0 ]; then
        log_warn 'set_memory_swap skip, swapon -a error'
    fi

    local sysctl_conf_file='/etc/sysctl.conf'
    sed -i '/vm.swappiness/d' "$sysctl_conf_file"
    echo 'vm.swappiness = 10' >> "$sysctl_conf_file"
    sysctl --load

    log_info 'set_memory_swap end, show current value'
    free -m
}



# 获取系统正在监听的 TCP 端口
function show_tcp_listening(){
    if command -v 'ss' &> '/dev/null'; then
        log_info 'ss --tcp --listening --numeric --processes'
        ss -tlnp
    elif command -v 'netstat' &> '/dev/null'; then
        log_info 'netstat --all --tcp --listening --numeric --programs | grep '"'"'LISTEN'"'"''
        netstat -atlnp | grep 'LISTEN'
    else
        log_error 'No available command found: netstat / ss'
        return 1
    fi
}



log_success 'My.sh is loaded'
