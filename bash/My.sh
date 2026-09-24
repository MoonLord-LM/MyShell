#!/bin/bash

# MyShell
# 开源地址：https://github.com/MoonLord-LM/MyShell
# 加载函数：source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )



# 检查入参（最多9个）必须全都不为空字符串，否则报错
function check_parameter(){
    if [ "${FUNCNAME[1]}" != '' ]; then
        local current_function="${FUNCNAME[1]}"
    else
        local current_function="${FUNCNAME[0]}"
    fi
    local red_color='\e[1;31m'
    local color_end='\e[0m'
    if [ "$#" -ge '1' ] && [ "$1" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $1 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '2' ] && [ "$2" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $2 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '3' ] && [ "$3" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $3 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '4' ] && [ "$4" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $4 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '5' ] && [ "$5" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $5 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '6' ] && [ "$6" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $6 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '7' ] && [ "$7" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $7 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '8' ] && [ "$8" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $8 ] is empty' && echo -ne "$color_end"
        return 1
    fi
    if [ "$#" -ge '9' ] && [ "$9" == '' ]; then
        echo -ne "$red_color" && echo "$current_function"': parameter [ $9 ] is empty' && echo -ne "$color_end"
        return 1
    fi
}



# 输出红色的错误信息（$1）
function log_error(){
    check_parameter "$1" || return 1
    echo -ne '\e[1;31m' && echo "$1" && echo -ne '\e[0m'
}
# 输出绿色的成功信息（$1）
function log_success(){
    check_parameter "$1" || return 1
    echo -ne '\e[1;32m' && echo "$1" && echo -ne '\e[0m'
}
# 输出黄色的警告信息（$1）
function log_warn(){
    check_parameter "$1" || return 1
    echo -ne '\e[1;33m' && echo "$1" && echo -ne '\e[0m'
}
# 输出深蓝色的提示信息（$1）
function log_info(){
    check_parameter "$1" || return 1
    echo -ne '\e[1;34m' && echo "$1" && echo -ne '\e[0m'
}
# 输出紫色的提示信息（$1）
function log_attention(){
    check_parameter "$1" || return 1
    echo -ne '\e[1;35m' && echo "$1" && echo -ne '\e[0m'
}
# 输出浅蓝色的提示信息（$1）
function log_notice(){
    check_parameter "$1" || return 1
    echo -ne '\e[1;36m' && echo "$1" && echo -ne '\e[0m'
}



# 获取系统的版本信息
function get_system_version(){
    local centos_version_file='/etc/redhat-release'
    local ubuntu_version_file='/etc/issue'
    if [ -f "$centos_version_file" ]; then
        local version=$(cat "$centos_version_file")
        echo "$version"
        return 0
    fi
    if [ -f "$ubuntu_version_file" ]; then
        local version=$(cat "$ubuntu_version_file")
        echo "$version"
        return 0
    fi
    log_error 'get_system_version failed, unknown system'
    return 1
}
# 判断系统是否是 Ubuntu
function check_system_is_ubuntu(){
    get_system_version | grep 'Ubuntu' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info 'check_system_is_ubuntu: false'
        return 1
    fi
    local version=$(get_system_version)
    log_info "check_system_is_ubuntu: $version"
}
# 判断系统是否是 Debian
function check_system_is_debian(){
    get_system_version | grep 'Debian' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info 'check_system_is_debian: false'
        return 1
    fi
    local version=$(get_system_version)
    log_info "check_system_is_debian: $version"
}



# 判断指定命令（$1）是否存在
function check_command_exist(){
    check_parameter "$1" || return 1
    local cmd=$1
    command -v "$cmd" > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info "check_command_exist: \"$cmd\" does not exist"
        return 1
    fi
    local cmd_file_path=$(command -v "$cmd")
    log_info "check_command_exist: \"$cmd\" exists in \"$cmd_file_path\""
}
# 更新软件（保守，允许安装新依赖，不删除已安装的软件）
function update_software(){
    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        check_system_is_debian
        if [ $? -ne 0 ]; then
            log_error 'update_software failed, unknown system'
            return 1
        fi
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
}
# 更新软件（激进，允许安装新依赖，允许删除已安装的软件）
function update_software_aggressive(){
    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        check_system_is_debian
        if [ $? -ne 0 ]; then
            log_error 'update_software_aggressive failed, unknown system'
            return 1
        fi
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
}
# 安装指定名称（$1）的软件
function install_software(){
    check_parameter "$1" || return 1
    local software=$1

    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        check_system_is_debian
        if [ $? -ne 0 ]; then
            log_error "install_software failed, unknown system"
            return 1
        fi
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
    local software=$1

    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        check_system_is_debian
        if [ $? -ne 0 ]; then
            log_error "remove_software failed, unknown system"
            return 1
        fi
    fi

    dpkg-query -W -f='${Status}' "$software" 2> '/dev/null' | grep -q 'install ok installed'
    if [ $? -eq 0 ]; then
        apt remove -y "$software"
        apt autoremove -y
        dpkg --purge "$software"
        if [ $? -ne 0 ]; then
            log_error "remove_software failed, \"$software\" remove error"
            return 1
        else
            log_info "remove_software end, \"$software\" remove ok"
        fi
    else
        log_info "remove_software skip, \"$software\" is already removed"
    fi
}
# 准备常用的命令
function prepare_common_command(){
    check_command_exist 'netstat' || install_software 'net-tools'
    check_command_exist 'wget' || install_software 'wget'
    check_command_exist 'curl' || install_software 'curl'

    check_command_exist 'git' || install_software 'git'
    check_command_exist 'mvn' || install_software 'maven'

    check_command_exist 'make' || install_software 'make'
    check_command_exist 'cmake' || install_software 'cmake'
    check_command_exist 'gcc' || install_software 'gcc'
    check_command_exist 'g++' || install_software 'g++'

    check_command_exist 'python3' || install_software 'python3'
    check_command_exist 'java' || install_software 'openjdk'
}
# 查看系统已安装的程序和版本
function show_software_list(){
    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        check_system_is_debian
        if [ $? -ne 0 ]; then
            log_error "show_software_list failed, unknown system"
            return 1
        fi
    fi

    log_info "dpkg-query -W -f='\${Package} \${Version}' | grep 'install ok installed'"
    dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2> '/dev/null' | grep 'install ok installed' | awk '{print $1" "$2}'
}
# 搜索已安装的软件（$1 为关键字，模糊匹配包名和描述），显示名称和版本
function show_software(){
    check_parameter "$1" || return 1
    local keyword=$1

    check_system_is_ubuntu
    if [ $? -ne 0 ]; then
        check_system_is_debian
        if [ $? -ne 0 ]; then
            log_error "show_software failed, unknown system"
            return 1
        fi
    fi

    local result
    result=$(dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2> '/dev/null' \
        | grep 'install ok installed' | awk '{print $1" "$2}' | grep -i "$keyword")
    if [ "$result" == '' ]; then
        # 包名没匹配到时，再按软件描述搜索
        result=$(dpkg-query -W -f='${binary:Package}|${Version}|${Status}|${Description}\n' 2> '/dev/null' \
            | grep 'install ok installed' | grep -i "$keyword" | awk -F'|' '{print $1" "$2}')
    fi
    if [ "$result" == '' ]; then
        log_info "show_software: no software found by keyword \"$keyword\""
        return 1
    fi
    log_info "show_software: search \"$keyword\""
    echo "$result"
}



# 设置系统时区为中国时区（GMT+08:00）
function set_timezone_china(){
    local old_time=$(date "+%Y-%m-%d %H:%M:%S %z")
    log_info "set_timezone_china begin, old time is \"$old_time\""
    ln -sfn '/usr/share/zoneinfo/Asia/Shanghai' '/etc/localtime'
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
    sysctl 'net.ipv4.tcp_fastopen'

    # 尝试加载 bbr 模块，并试探当前内核是否支持 bbr（不支持时直接报错返回，不修改配置文件）
    modprobe 'tcp_bbr' > '/dev/null' 2>&1
    sysctl -w 'net.ipv4.tcp_congestion_control=bbr' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_error 'set_tcp_congestion_control_bbr failed, kernel does not support bbr'
        return 1
    fi

    # 修改配置前先备份
    local sysctl_conf_file='/etc/sysctl.conf'
    backup_file "$sysctl_conf_file" > '/dev/null' 2>&1

    sed -i '/net.ipv4.tcp_congestion_control/d' "$sysctl_conf_file"
    sed -i '/net.core.default_qdisc/d' "$sysctl_conf_file"
    sed -i '/net.ipv4.tcp_fastopen/d' "$sysctl_conf_file"

    echo 'net.ipv4.tcp_congestion_control = bbr' >> "$sysctl_conf_file"
    echo 'net.core.default_qdisc = fq' >> "$sysctl_conf_file"
    echo 'net.ipv4.tcp_fastopen = 3' >> "$sysctl_conf_file"

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
    sysctl 'net.ipv4.tcp_fastopen'
}
# 设置 /usr/memory_swap 文件为唯一的虚拟内存，并保证物理内存和虚拟内存的总量在 4GB 或以上
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

    # 先创建新 swap 文件并启用；若 /usr/memory_swap 已启用，需先停用
    local swap_file='/usr/memory_swap'
    swapoff "$swap_file" > '/dev/null' 2>&1
    dd if='/dev/zero' of="$swap_file" bs='1M' count="$(( need_size + 1 ))"
    if [ $? -ne 0 ]; then
        log_error 'set_memory_swap failed, dd error'
        return 1
    fi
    chmod 600 "$swap_file"
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

    # 新 swap 已生效，停用并删除旧的 swap 文件，同时从 /etc/fstab 中移除对应条目（swap 分区不动）
    local fstab_file='/etc/fstab'
    local swap_path
    while read -r swap_path; do
        if [ "$swap_path" != "$swap_file" ] && [ -f "$swap_path" ]; then
            log_info "set_memory_swap remove old swap file: \"$swap_path\""
            swapoff "$swap_path" > '/dev/null' 2>&1
            sed -i "\|^[[:space:]]*$swap_path[[:space:]]|d" "$fstab_file"
            rm -f "$swap_path"
        fi
    done < <(awk '$2=="file"{print $1}' '/proc/swaps')

    # 写入 /etc/fstab 以便重启后自动挂载
    grep -q "$swap_file" "$fstab_file"
    if [ $? -ne 0 ]; then
        echo "$swap_file swap swap defaults 0 0" >> "$fstab_file"
    fi
    mount -a

    local sysctl_conf_file='/etc/sysctl.conf'
    sed -i '/vm.swappiness/d' "$sysctl_conf_file"
    echo 'vm.swappiness = 10' >> "$sysctl_conf_file"
    sysctl --load

    log_info 'set_memory_swap end, show current value'
    free -m
}
# 设置 iptables 防火墙允许所有流量通过（临时测试使用，重启后恢复默认）
function set_iptables_accept_all(){
    check_command_exist 'iptables' || install_software 'iptables'
    if [ $? -ne 0 ]; then
        log_error "set_iptables_accept_all failed, iptables not found"
        return 1
    fi

    # 清空所有表（filter / nat / mangle / raw / security）的规则和自定义链
    local table
    for table in 'filter' 'nat' 'mangle' 'raw' 'security'; do
        iptables -t "$table" --flush > '/dev/null' 2>&1
        iptables -t "$table" --delete-chain > '/dev/null' 2>&1
    done

    iptables --policy INPUT ACCEPT
    iptables --policy OUTPUT ACCEPT
    iptables --policy FORWARD ACCEPT
    iptables --list
}



# 备份指定路径的文件（$1），保存到 [ - 时间.bak] 后缀的文件中
function backup_file(){
    check_parameter "$1" || return 1
    local source_file=$1

    local current_time=$(date "+%Y-%m-%d %H:%M:%S %z")
    local backup_new_file="$source_file - $current_time.bak"

    if [ ! -f "$source_file" ]; then
        log_error "file \"$source_file\" is not found"
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





#### 环境准备 ####
# update_software
# update_software_aggressive
# prepare_common_command

#### 系统设置 ####
# set_timezone_china
# set_tcp_congestion_control_bbr
# set_memory_swap_to_4GB
# set_iptables_accept_all

#### 查看信息 ####
# get_system_version
# show_software_list
# show_tcp_listening

log_info 'My.sh is loaded'
