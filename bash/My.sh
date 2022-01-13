#!/bin/bash

# MyShell 公共函数库
# 使用方法：source <( wget -O- 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )



# 参数设置：
github_repository='https://github.com/MoonLord-LM/MyShell'



# 检查入参（最多9个）必须全都不为空字符串，否则报错
function check_parameter(){
    if [ "${FUNCNAME[1]}" != '' ]; then
        current_function="${FUNCNAME[1]}"
    else
        current_function="${FUNCNAME[0]}"
    fi
    red_color='\e[1;31m'
    color_end='\e[0m'
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



# 设置系统时区为中国时区（GMT+08:00）
function set_china_timezone(){
    cp -f '/usr/share/zoneinfo/Asia/Shanghai' '/etc/localtime'
    current_time=$(date "+%Y-%m-%d %H:%M:%S %z")
    log_info "set_china_timezone ok, current time: \"$current_time\""
}



# 获取系统的版本信息
function get_system_version(){
    centos_version_file='/etc/redhat-release'
    ubuntu_version_file='/etc/issue'
    if [ -f "$centos_version_file" ]; then
        version=$(cat $centos_version_file)
        echo "$version"
        return 0
    fi
    if [ -f "$ubuntu_version_file" ]; then
        version=$(cat $ubuntu_version_file)
        echo "$version"
        return 0
    fi
    log_error 'get_system_version failed'
    return 1
}



# 备份指定路径的文件（$1），保存到 [ - 时间.bak] 后缀的文件中
function backup_file(){
    check_parameter "$1" || return 1
    current_time=$(date "+%Y-%m-%d %H:%M:%S %z")
    source_file_name=$1
    backup_file_name="$source_file_name - $current_time.bak"
    if [ ! -f "$source_file_name" ]; then
        log_error "file \"$source_file_name\" is not found"
        return 1
    fi
    if [ -f "$backup_file_name" ]; then
        log_error "file \"$backup_file_name\" already exists"
        return 1
    fi
    if [ ! -f "$backup_file_name" ]; then
        cp -f "$source_file_name" "$backup_file_name"
    fi
    if [ ! -f "$backup_file_name" ]; then
        log_error "file \"$backup_file_name\" copy failed"
        return 1
    fi
    log_info "backup_file ok, from \"$source_file_name\" to \"$backup_file_name\""
}



# 判断指定命令（$1）是否存在
function check_command_exist(){
    check_parameter "$1" || return 1
    cmd=$1
    command -v "$cmd" > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info "check_command_exist: \"$cmd\" does not exist"
        return 1
    fi
    cmd_file_path=$(command -v "$cmd")
    log_info "check_command_exist: \"$cmd\" exists in \"$cmd_file_path\""
}



# 判断系统是否是 CentOS
function check_system_is_centos(){
    get_system_version | grep 'CentOS' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info 'check_system_is_centos: false'
        return 1
    fi
    version=$(get_system_version)
    log_info "check_system_is_centos: $version"
}
# 判断系统是否是 Ubuntu
function check_system_is_ubuntu(){
    get_system_version | grep 'Ubuntu' > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        log_info 'check_system_is_ubuntu: false'
        return 1
    fi
    version=$(get_system_version)
    log_info "check_system_is_ubuntu: $version"
}



# 安装指定名称（$1）的软件
function install_software(){
    check_parameter "$1" || return 1
    software=$1

    # 软件别名处理 begin
    if [ "$software" == 'g++' ]; then
        check_system_is_centos
        if [ $? -eq 0 ]; then
            software='gcc-c++'
        fi
    fi
    # 软件别名处理 end

    check_system_is_centos
    if [ $? -eq 0 ]; then
        yum list installed "$software"
    else
        check_system_is_ubuntu
        if [ $? -eq 0 ]; then
            apt list --installed "$software" && apt list --installed "$software" | grep '\[installed\]' | grep "$software" > '/dev/null' 2>&1
        else
            log_error 'install_software: unknown system, install check failed'
            return 1
        fi
    fi
    if [ $? -ne 0 ]; then
        check_system_is_centos
        if [ $? -eq 0 ]; then
            yum install -y "$software"
        else
            check_system_is_ubuntu
            if [ $? -eq 0 ]; then
                apt install -y "$software"
            else
                log_error 'install_software: unknown system, install failed'
                return 1
            fi
        fi
        if [ $? -ne 0 ]; then
            log_error "install_software: \"$software\" install failed"
            return 1
        else
            log_info "install_software: \"$software\" install ok"
        fi
    else
        log_info "install_software: \"$software\" is intalled"
    fi
}
# 卸载指定名称（$1）的软件
function remove_software(){
    check_parameter "$1" || return 1
    software=$1
    check_system_is_centos
    if [ $? -eq 0 ]; then
        yum list installed "$software"
    else
        check_system_is_ubuntu
        if [ $? -eq 0 ]; then
            apt list --installed "$software" && apt list --installed "$software" | grep '\[installed\]' | grep "$software" > '/dev/null' 2>&1
        else
            log_error 'remove_software: unknown system, remove check failed'
            return 1
        fi
    fi
    if [ $? -eq 0 ]; then
        check_system_is_centos
        if [ $? -eq 0 ]; then
            yum remove -y "$software"
        else
            check_system_is_ubuntu
            if [ $? -eq 0 ]; then
                apt remove -y "$software"
            else
                log_error 'remove_software: unknown system, remove failed'
                return 1
            fi
        fi
        if [ $? -ne 0 ]; then
            log_error "remove_software: \"$software\" remove failed"
            return 1
        else
            log_info "remove_software: \"$software\" remove ok"
        fi
    else
        log_info "remove_software: \"$software\" is removed"
    fi
}



# 安装常用的命令
function install_common_command(){
    check_command_exist 'git' || install_software 'git'
    check_command_exist 'mvn' || install_software 'maven'
    check_command_exist 'make' || install_software 'make'
    check_command_exist 'cmake' || install_software 'cmake'
    check_command_exist 'gcc' || install_software 'gcc'
    check_command_exist 'g++' || install_software 'g++'
    check_command_exist 'python2' || install_software 'python2'
    check_command_exist 'python3' || install_software 'python3'
    check_command_exist 'pip3' || install_software 'python3-pip'
    
}



### TODO ###
echo 'My.sh is loaded'


