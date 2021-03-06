#!/bin/bash

# MyShell 公共函数库
# source ./My.sh


# 参数设置：
github_repository='https://github.com/MoonLord-LM/MyShell'
aliyun_base_repo='http://mirrors.aliyun.com/repo/Centos-7.repo'
aliyun_epel_repo='http://mirrors.aliyun.com/repo/epel-7.repo'
aliyun_simple_pypi='http://mirrors.aliyun.com/pypi/simple/'



# 输出红色的错误信息（$1）
function error(){
    if [ "$1" == "" ]; then
        echo -ne '\e[1;31m' && echo 'error: missing parameter!' && echo -ne '\e[0m'
        return 1
    fi
    echo -ne '\e[1;31m' && echo "$1" && echo -ne '\e[0m'
}
# 输出绿色的成功信息（$1）
function success(){
    if [ "$1" == "" ]; then
        error 'success: missing parameter!'
        return 1
    fi
    echo -ne '\e[1;32m' && echo "$1" && echo -ne '\e[0m'
}
# 输出黄色的警告信息（$1）
function warn(){
    if [ "$1" == "" ]; then
        error 'warn: missing parameter!'
        return 1
    fi
    echo -ne '\e[1;33m' && echo "$1" && echo -ne '\e[0m'
}
# 输出深蓝色的提示信息（$1）
function info(){
    if [ "$1" == "" ]; then
        error 'info: missing parameter!'
        return 1
    fi
    echo -ne '\e[1;34m' && echo "$1" && echo -ne '\e[0m'
}
# 输出紫色的提示信息（$1）
function attention(){
    if [ "$1" == "" ]; then
        error 'attention: missing parameter!'
        return 1
    fi
    echo -ne '\e[1;35m' && echo "$1" && echo -ne '\e[0m'
}
# 输出浅蓝色的提示信息（$1）
function notice(){
    if [ "$1" == "" ]; then
        error 'notice: missing parameter!'
        return 1
    fi
    echo -ne '\e[1;36m' && echo "$1" && echo -ne '\e[0m'
}


# 类似 PHP 的 die 函数，输出错误信息（$1），并立即退出脚本
export TOP_PID=$$
trap 'exit 1' TERM
function die(){
    if [ "$1" == "" ]; then
        error 'die: missing parameter!'
        return 1
    fi
    error "$1"
    tmp=`echo $BASHOPTS | grep 'login_shell'`
    if [ "${BASH_SOURCE-$0}" != "" ] && [ "$tmp" == "" ]; then
        kill -s TERM $TOP_PID
    fi
}


# 备份指定路径的文件（$1），保存到 .bak 后缀的文件中
function backup_file(){
    if [ "$1" == "" ]; then
        die 'backup_file: missing parameter!'
        return 1
    fi
    info "backup_file: \"$1\""
    file_name=$1
    new_file="${file_name}.bak"
    if [ ! -f "$file_name" ]; then
        die "[ Error ] file \"$file_name\" is not found!"
        return 1
    fi
    if [ -f "$new_file" ]; then
        die "[ Error ] file \"$new_file\" already exists!"
    fi
    if [ ! -f "$new_file" ]; then
        cp -f "$file_name" "$new_file"
    fi
    if [ ! -f "$new_file" ]; then
        die "[ Error ] file \"$file_name\" copy failed!"
        return 1
    fi
}


# 判断指定名称（$1）的函数或命令是否存在
function check_exist(){
    if [ "$1" == "" ]; then
        die 'check_exist: missing parameter!'
        return 1
    fi
    info "check_exist: \"$1\""
    cmd=$1
    hash -d "$cmd" > '/dev/null' 2>&1
    command -v "$cmd" > '/dev/null' 2>&1
    if [ $? -ne 0 ]; then
        return 1
    fi
}
# 使用 yum 安装指定名称（$1）的依赖组件
function install_require(){
    if [ "$1" == "" ]; then
        die 'install_require: missing parameter!'
        return 1
    fi
    info "install_require: \"$1\""
    software=$1
    tmp=`yum list installed | grep "$software"`
    if [ "$tmp" == "" ]; then
        yum install "$software" -y
        if [ $? -ne 0 ]; then
            die "[ Error ] \"$software\" install failed!"
            return 1
        fi
    fi
}
# 使用 yum 卸载指定名称（$1）的依赖组件
function remove_unneeded(){
    if [ "$1" == "" ]; then
        die 'remove_unneeded: missing parameter!'
        return 1
    fi
    info "remove_unneeded: \"$1\""
    software=$1
    systemctl stop "$software"
    systemctl disable "$software"
    systemctl daemon-reload
    tmp=`yum list installed | grep "$software"`
    if [ "$tmp" != "" ]; then
        yum remove "$software" -y
        if [ $? -ne 0 ]; then
            die "[ Error ] \"$software\" remove failed!"
            return 1
        fi
    fi
}


# 设置 yum 的 base_repo 源为指定的链接（$1）
base_repo_file='/etc/yum.repos.d/CentOS-Base.repo'
function set_base_repo(){
    if [ "$1" == "" ]; then
        die 'set_base_repo: missing parameter!'
        return 1
    fi
    info "set_base_repo: \"$1\""
    repo_url=$1
    check_exist 'wget' || install_require 'wget'
    wget "$repo_url" -O "$base_repo_file" --no-verbose
}
# 设置 yum 的 base_repo 源为指定的链接（$1）
epel_repo_file='/etc/yum.repos.d/CentOS-Epel.repo'
function set_epel_repo(){
    if [ "$1" == "" ]; then
        die 'set_epel_repo: missing parameter!'
        return 1
    fi
    info "set_epel_repo: \"$1\""
    repo_url=$1
    check_exist 'wget' || install_require 'wget'
    wget "$repo_url" -O "$epel_repo_file" --no-verbose
}
# 设置 pip 的 pypi 源为指定的链接（$1）
pip_conf_file='/root/.pip/pip.conf'
function set_pypi(){
    if [ "$1" == "" ]; then
        die 'set_pypi: missing parameter!'
        return 1
    fi
    info "set_pypi: \"$1\""
    pypi_url=$1
    tmp="${pypi_url##*//}"
    pypi_host="${tmp%%/*}"
    notice "trust host: $pypi_host"
    pip_conf_dir="${pip_conf_file%%/pip.conf}"
    if [ ! -d "$pip_conf_dir" ]; then
        mkdir -m 755 -p "$pip_conf_dir"
    fi
    if [ ! -f "$pip_conf_file" ]; then
        touch "$pip_conf_file"
        chmod 755 "$pip_conf_file"
    fi
    echo '[global]' > "$pip_conf_file"
    echo "index-url=$pypi_url" >> "$pip_conf_file"
    echo '[install]' >> "$pip_conf_file"
    echo "trusted-host=$pypi_host" >> "$pip_conf_file"
}


# 从指定的链接（$1）下载 .tar.gz 压缩包，并检查 MD5 值（$2），然后解压到当前目录下
function prepare_source(){
    if [ "$1" == "" ]; then
        die 'prepare_source: missing parameter!'
        return 1
    fi
    info "prepare_source: \"$1\""
    file_url=$1
    file_name="${file_url##*/}"
    output_dir="${file_name%%.tar.gz}"
    if [ -f $file_name ]; then
        notice "file already exists: $file_name"
        if [ "$2" != "" ]; then
            file_md5=$2
            notice "show `md5sum $file_name | grep $file_md5`"
            md5sum $file_name | grep $file_md5
            tmp=`md5sum $file_name | grep $file_md5`
            if [ "$tmp" == "" ]; then
                notice "check file md5 error, delete file: $file_name"
                notice "target md5 is: [ $file_md5 ], but current md5 is: [ $tmp ]"
                rm -rf "$file_name"
            else
                notice "check file md5 ok: $file_name"
            fi
        fi
    fi
    if [ ! -f $file_name ]; then
        notice "begin download: $file_name"
        check_exist 'wget' || install_require 'wget'
        wget "$file_url" -O "$file_name" --no-verbose
    fi
    if [ ! -s $file_name ]; then
        die "[ Error ] \"$file_name\" download failed!"
        return 1
    fi
    if [ -d "$output_dir" ]; then
        rm -rf "$output_dir"
    fi
    if [ ! -d "$output_dir" ]; then
        notice "begin extract: $file_name"
        tar -zxvf "$file_name" -C ./
    fi
    if [ ! -d "$output_dir" ]; then
        die "[ Error ] \"$file_name\" extract failed!"
        return 1
    fi
}
# 从预定义的 GitHub 仓库下载指定路径（$1）的文件，并保存到当前目录下
function prepare_github_source(){
    if [ "$1" == "" ]; then
        die 'prepare_github_source: missing parameter!'
        return 1
    fi
    info "prepare_github_source: \"$1\""
    file_url=$1
    tmp="${github_repository/github.com/raw.githubusercontent.com}"
    file_url="$tmp/master/$1"
    file_name="${file_url##*/}"
    if [ -f $file_name ]; then
        rm -rf "$file_name"
    fi
    notice "begin download: $file_name"
    check_exist 'wget' || install_require 'wget'
    wget "$file_url" -O "$file_name"
    if [ ! -s $file_name ]; then
        die "[ Error ] \"$file_name\" download failed!"
        return 1
    fi
}


# 将程序（$1）加入 /etc/rc.d/rc.local 配置文件中，设置开机启动
rc_local_file='/etc/rc.d/rc.local'
function set_autorun(){
    if [ "$1" == "" ]; then
        die 'set_autorun: missing parameter!'
        return 1
    fi
    info "set_autorun: \"$1\""
    run_cmd=$1
    chmod +x "$rc_local_file"
    systemctl start 'rc-local.service'
    systemctl enable 'rc-local.service'
    systemctl daemon-reload
    while read line
    do
        tmp=`echo $line | grep '^[^#].*$'`
        if [ "$tmp" != "" ] && [ "$tmp" == "$run_cmd" ]; then
            notice 'already set autorun'
            return 0
        fi
    done < "$rc_local_file"
    echo $line
    if [ "$line" != "" ]; then
        echo "" >> "$rc_local_file"
    fi
    echo "$run_cmd" >> "$rc_local_file"
    notice 'set autorun successfully'
}
# 将程序（$1）从 /etc/rc.d/rc.local 配置文件中移除，取消开机启动
function unset_autorun(){
    if [ "$1" == "" ]; then
        die 'unset_autorun: missing parameter!'
        return 1
    fi
    info "unset_autorun: \"$1\""
    run_cmd=$1
    chmod +x "$rc_local_file"
    systemctl start 'rc-local.service'
    systemctl enable 'rc-local.service'
    systemctl daemon-reload
    tmp_line_num=0
    while read line
    do
        tmp_line_num=$(( $tmp_line_num + 1 ))
        tmp=`echo $line | grep '^[^#].*$'`
        if [ "$tmp" != "" ] && [ "$tmp" == "$run_cmd" ]; then
            sed -i "$tmp_line_num d" "$rc_local_file"
            unset_autorun "$run_cmd"
            notice 'unset autorun successfully'
            return 0
        fi
    done < "$rc_local_file"
    notice 'not found'
}


# 创建指定名称（$1）的用户和用户组，并设置用户的标注（$2）和主目录（$3）
function add_user_group(){
    if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
        die 'add_user_group: missing parameter!'
        return 1
    fi
    info "add_user_group: \"$1\" \"$2\" \"$3\""
    user_group_name=$1
    user_comment=$2
    home_dir=$3
    tmp=`cat '/etc/group' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        groupadd $user_group_name
    fi
    tmp=`cat '/etc/group' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        die "[ Error ] add group \"$user_group_name\" failed!"
        return 1
    fi
    tmp=`cat '/etc/passwd' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        useradd $user_group_name -g $user_group_name -s /bin/false
    fi
    tmp=`cat '/etc/passwd' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        die "[ Error ] add user \"$user_group_name\" failed!"
        return 1
    fi
    if [ ! -d "$home_dir" ]; then
        mkdir -m 755 -v -p "$home_dir"
    fi
    if [ ! -d "$home_dir" ]; then
        die "[ Error ] create home directory \"$home_dir\" failed!"
        return 1
    fi
    usermod -c "$user_comment" -d "$home_dir" $user_group_name
    chgrp -R $user_group_name "$home_dir"
    chown -R $user_group_name "$home_dir"
}
# 为指定名称（$1）的用户和用户组，创建目录（$2），并设置 755 权限
function set_user_dir(){
    if [ "$1" == "" ] || [ "$2" == "" ]; then
        die 'set_user_dir: missing parameter!'
        return 1
    fi
    info "set_user_dir: \"$1\" \"$2\""
    user_name=$1
    new_dir=$2
    if [ ! -d "$new_dir" ]; then
        mkdir -m 755 -v -p "$new_dir"
    fi
    if [ ! -d "$new_dir" ]; then
        die "[ Error ] create directory \"$new_dir\" failed!"
        return 1
    fi
    chgrp -R $user_name "$new_dir"
    chown -R $user_name "$new_dir"
}
# 为指定名称（$1）的用户和用户组，创建文件（$2），并设置 755 权限
function set_user_file(){
    if [ "$1" == "" ] || [ "$2" == "" ]; then
        die 'set_user_file: missing parameter!'
        return 1
    fi
    info "set_user_file: \"$1\" \"$2\""
    user_name=$1
    new_file=$2
    if [ ! -f "$new_file" ]; then
        touch "$new_file"
        chmod 755 "$new_file"
    fi
    if [ ! -f "$new_file" ]; then
        die "[ Error ] create file \"new_file\" failed!"
        return 1
    fi
    chgrp $user_name "$new_file"
    chown $user_name "$new_file"
}


# 搜索文件（$1）中的唯一字符串标记（$2），将指定行的内容，修改为字符串（$3）
function modify_config_file(){
    if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
        die 'modify_config_file: missing parameter!'
        return 1
    fi
    info "modify_config_file: \"$1\" \"$2\" \"$3\""
    file_name=$1
    search_tag=$2
    new_content=$3
    tmp=`cat "$file_name" | grep -n "$search_tag" | wc -l`
    if [ "$tmp" == "0" ]; then
        notice 'find no line, add new config line!'
        echo "$new_content" > "$file_name"
        return 0
    fi
    if [ "$tmp" != "1" ]; then
        die "[ Error ] find more than one line config in \"file_name\"!"
        return 1
    fi
    line_num=`cat "$file_name" | grep -n "$search_tag" | awk -F':' '{print $1}'`
    notice "modify line num: $line_num"
    sed -i "$line_num c\\$new_content" "$file_name"
}


# 设置 /memory_swap 为虚拟内存，保证物理内存和虚拟内存的总量在 4GB
swap_file='/memory_swap'
fstab_file='/etc/fstab'
sysctl_conf_file='/etc/sysctl.conf'
function set_memory_swap(){
    info 'set_memory_swap'
    mem_size=`free -k | grep 'Mem:' | awk -F' ' '{print $2}'`
    add_size=$(( 1024 * 1024 * 4 - $mem_size ))
    if [ "$add_size" -le "0" ]; then
        notice 'physical memory is enough'
        return 0
    fi
    swap_size=`free -k | grep 'Swap:' | awk -F' ' '{print $2}'`
    add_size=$(( $add_size - $swap_size ))
    if [ "$add_size" -le "0" ]; then
        notice 'virtual memory is enough'
        return 0
    fi
    notice "add swap memory: $add_size KB"
    tmp=`dd if='/dev/zero' of="$swap_file" bs=1024 count=$add_size 2>&1 | grep 'busy'`
    if [ "$tmp" != "" ]; then
        notice 'memory swap file already exists'
        return 0
    fi
    mkswap "$swap_file"
    chmod 600 "$swap_file"
    swapon "$swap_file"
    tmp=`cat "$fstab_file" | grep "$swap_file"`
    if [ "$tmp" == "" ]; then
        echo "$swap_file swap swap default 0 0" >> "$fstab_file"
    else
        modify_config_file "$fstab_file" "$swap_file" "$swap_file swap swap default 0 0"
    fi
    cat "$fstab_file"
    mount -a
    modify_config_file "$sysctl_conf_file" 'vm.swappiness' 'vm.swappiness=10'
    cat "$sysctl_conf_file" | grep 'vm.swappiness'
    sysctl -p | grep 'vm.swappiness'
    notice 'show `free -m`:'
    free -m
}
# 删除 /memory_swap 的虚拟内存设置
function unset_memory_swap(){
    info 'unset_memory_swap'
    swapoff "$swap_file"
    if [ ! -f "$swap_file" ]; then
        notice 'memory swap file does not exist'
    else
        rm -rf "$swap_file"
    fi
    tmp=`cat "$fstab_file" | grep "$swap_file"`
    if [ "$tmp" != "" ]; then
        new_setting=`cat "$fstab_file" | grep -v "$swap_file"`
        echo "$new_setting" > "$fstab_file"
    fi
    cat "$fstab_file"
    mount -a
    modify_config_file "$sysctl_conf_file" 'vm.swappiness' 'vm.swappiness=0'
    cat "$sysctl_conf_file" | grep 'vm.swappiness'
    sysctl -p | grep 'vm.swappiness'
    notice 'show `free -m`:'
    free -m
}


# 显示指定目录（$1）的磁盘使用情况
function show_disk_usage(){
    if [ "$1" == "" ]; then
        die 'show_disk_usage: missing parameter!'
        return 1
    fi
    info "show_disk_usage: \"$1\""
    dir=$1
    if [ ! -d "$dir" ]; then
        die "[ Error ] \"$dir\" is not a directory!"
        return 1
    fi
    notice 'show `df -h | grep -v '"'"'tmpfs'"'"'`:'
    df -h | grep -v 'tmpfs'
    notice 'show `du -h --max-depth=1`:'
    cd "$dir"
    du -h --max-depth=1
    cd - > '/dev/null'
}


# 显示服务器的 TCP 连接信息
function show_tcp(){
    info 'show_tcp'
    notice 'show `netstat -atnlp`:'
    netstat -atnlp
}
# 显示服务器的 UDP 连接信息
function show_udp(){
    info 'show_udp'
    notice 'show `netstat -aunlp`:'
    netstat -aunlp
}
# 显示服务器正在监听的 TCP 端口号
function show_listen(){
    info 'show_listen'
    notice 'show `netstat -atnlp | grep '"'"'LISTEN'"'"'`:'
    netstat -atnlp | grep 'LISTEN'
}
# 显示服务器的网络连接信息
function show_netstat(){
    info 'show_netstat'
    show_tcp
    show_udp
    show_listen
}


# 显示系统运行状态
function show(){
    info 'show'
    check_exist 'virt-what' || install_require 'virt-what'
    echo "CPU Core:  `grep 'processor' '/proc/cpuinfo' | wc -l` \
          Virtual: `virt-what` \
          Type: `grep 'model name' '/proc/cpuinfo' | awk -F':' '{print $2}'`"
    echo
    echo "Now`uptime`"
    top -b -n 1 | head -n 3 | tail -n 2
    echo
    free -h
    echo
    df -h | grep -v 'tmpfs'
    echo
    netstat -atnlp | grep 'LISTEN'
    echo
}


# 初始化（备份重要文件，安装、升级基础组件）
function my_init(){
    info 'my_init'

    backup_file "$base_repo_file"
    backup_file "$epel_repo_file"
    backup_file "$rc_local_file"
    backup_file "$fstab_file"
    backup_file "$sysctl_conf_file"

    set_base_repo "$aliyun_base_repo"
    set_epel_repo "$aliyun_epel_repo"
    yum clean all
    rm -rf '/var/cache/yum'
    yum makecache
    check_exist 'ifconfig' || install_require 'net-tools'
    check_exist 'make' || install_require 'make'
    check_exist 'cmake' || install_require 'cmake'
    check_exist 'gcc' || install_require 'gcc'
    check_exist 'g++' || install_require 'gcc-c++'
    check_exist 'python' || install_require 'python'
    check_exist 'easy_install' || install_require 'python-setuptools-devel'
    check_exist 'pip' || install_require 'python2-pip'
    set_pypi "$aliyun_simple_pypi"
    pip install --upgrade pip
    yum update -y

    check_exist 'postfix' && remove_unneeded 'postfix'

    prepare_github_source 'install/mysql_5.7.23.sh'
    prepare_github_source 'install/mysql_8.0.12.sh'
    prepare_github_source 'install/php_5.6.37.sh'
    prepare_github_source 'install/nginx_1.15.2.sh'
    prepare_github_source 'install/shadowsocks_2.8.2.sh'
    prepare_github_source 'install/shadowsocks_3.3.4.sh'
    prepare_github_source 'install/v2ray.sh'

    show
}
