#!/bin/bash

# MyShell 公共函数库


# 测试环境： 阿里云，CentOS 7.4 x64
aliyun_repo='http://mirrors.aliyun.com/repo/Centos-7.repo'


# 实现类似 PHP 的 die 函数，输出字符串（$1）并立即退出脚本
export TOP_PID=$$
trap 'exit 1' TERM
function die(){
    if [ "$1" == "" ]; then
        echo 'die: missing parameter!'
        return
    fi
    echo "$1"
    tmp=`echo $BASHOPTS | grep 'login_shell'`
    if [ $SHLVL -ne 1 ] && [ "${BASH_SOURCE-$0}" != "" ] && [ "$tmp" == "" ]; then
        kill -s TERM $TOP_PID
    fi
}


# 从指定的 repo 链接（$1）更新系统和软件
function update_repo(){
    if [ "$1" == "" ]; then
        die 'update_repo: missing parameter!'
        return
    fi
    echo "update_repo: \"$1\""
    repo_url=$1
    wget $repo_url -O '/etc/yum.repos.d/CentOS-Base.repo'
    yum clean all
    yum makecache
    yum update -y
}
# update_repo "$aliyun_repo" > '/dev/null' 2>&1


# 从指定的链接（$1）下载 .tar.gz 压缩包，并解压到当前目录下
function prepare_source(){
    if [ "$1" == "" ]; then
        die 'prepare_source: missing parameter!'
        return
    fi
    echo "prepare_source: \"$1\""
    source_url=$1
    file_name="${source_url##*/}"
    output_dir="${file_name%%.tar.gz}"
    if [ ! -f $file_name ]; then
        echo "begin download: $file_name"
        wget $source_url -O $file_name
    fi
    if [ ! -f $file_name ]; then
        die '[ Error ] download failed!'
        return
    fi
    if [ ! -d "$output_dir" ];then
        echo "begin extract: $file_name"
        tar -zxvf $file_name -C ./
    fi
    if [ ! -d "$output_dir" ];then
        die '[ Error ] extract failed!'
        return
    fi
}


# 将程序（$1）加入 /etc/rc.d/rc.local 配置文件中，设置开机启动
rc_local_file='/etc/rc.d/rc.local'
function set_autorun(){
    if [ "$1" == "" ]; then
        die 'set_autorun: missing parameter!'
        return
    fi
    echo "set_autorun: \"$1\""
    chmod +x "$rc_local_file"
    while read line
    do
        tmp=`echo $line | grep '^[^#].*$'`
        if [ "$tmp" != "" ] && [ "$tmp" == "$1" ]; then
            return
        fi
    done < "$rc_local_file"
    echo $line
    if [ "$line" != "" ]; then
        echo "" >> "$rc_local_file"
    fi
    echo "$1" >> "$rc_local_file"
}


# 将程序（$1）从 /etc/rc.d/rc.local 配置文件中移除，取消开机启动
function unset_autorun(){
    if [ "$1" == "" ]; then
        die 'unset_autorun: missing parameter!'
        return
    fi
    echo "unset_autorun: \"$1\""
    chmod +x "$rc_local_file"
    tmp_line_num=0
    while read line
    do
        tmp_line_num=$(( $tmp_line_num + 1 ))
        tmp=`echo $line | grep '^[^#].*$'`
        if [ "$tmp" != "" ] && [ "$tmp" == "$1" ]; then
            sed -i "$tmp_line_num d" "$rc_local_file"
            unset_autorun "$1"
            return
        fi
    done < "$rc_local_file"
}


# 创建指定名称（$1）的用户和用户组，并设置用户的标注（$2）和主目录（$3）
function add_user_group(){
    if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
        die 'add_user_group: missing parameter!'
        return
    fi
    echo "add_user_group: \"$1\" \"$2\" \"$3\""
    user_group_name=$1
    user_comment=$2
    home_dir=$3
    tmp=`cat '/etc/group' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        groupadd $user_group_name
    fi
    tmp=`cat '/etc/group' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        die '[ Error ] add group failed!'
        return
    fi
    tmp=`cat '/etc/passwd' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        useradd $user_group_name -g $user_group_name -s /bin/false
    fi
    tmp=`cat '/etc/passwd' | grep $user_group_name`
    if [ "$tmp" == "" ]; then
        die '[ Error ] add user failed!'
        return
    fi
    if [ ! -d "$home_dir" ];then
        mkdir -m 755 -v -p "$home_dir"
    fi
    if [ ! -d "$home_dir" ];then
        die '[ Error ] create home directory failed!'
        return
    fi
    usermod -c "$user_comment" -d "$home_dir" $user_group_name
    chgrp -R $user_group_name "$home_dir"
    chown -R $user_group_name "$home_dir"
}


# 为指定名称（$1）的用户和用户组，创建目录（$2），并设置 755 权限
function set_user_dir(){
    if [ "$1" == "" ] || [ "$2" == "" ]; then
        die 'set_user_dir: missing parameter!'
        return
    fi
    echo "set_user_dir: \"$1\" \"$2\""
    user_name=$1
    new_dir=$2
    if [ ! -d "$new_dir" ];then
        mkdir -m 755 -v -p "$new_dir"
    fi
    if [ ! -d "$new_dir" ];then
        die '[ Error ] create directory failed!'
        return
    fi
    chgrp -R $user_name "$new_dir"
    chown -R $user_name "$new_dir"
}


# 为指定名称（$1）的用户和用户组，创建文件（$2），并设置 755 权限
function set_user_file(){
    if [ "$1" == "" ] || [ "$2" == "" ]; then
        die 'set_user_file: missing parameter!'
        return
    fi
    echo "set_user_file: \"$1\" \"$2\""
    user_name=$1
    new_file=$2
    if [ ! -f "$new_file" ];then
        touch "$new_file"
        chmod 755 "$new_file"
    fi
    if [ ! -f "$new_file" ];then
        die '[ Error ] create file failed!'
        return
    fi
    chgrp $user_name "$new_file"
    chown $user_name "$new_file"
}


# 检查并安装指定名称（$1）的依赖组件
function install_require(){
    if [ "$1" == "" ]; then
        die 'install_require: missing parameter!'
        return 1
    fi
    echo "install_require: \"$1\""
    software=$1
    tmp=`yum list installed | grep "$1"`
    if [ "$tmp" == "" ]; then
        yum install "$software" -y
        if [ $? -ne 0 ]; then
            die '[ Error ] install failed!'
            return 1
        fi
    fi
}
install_require 'make' > '/dev/null' 2>&1
install_require 'cmake' > '/dev/null' 2>&1
install_require 'gcc' > '/dev/null' 2>&1
install_require 'gcc-c++' > '/dev/null' 2>&1


# 搜索文件（$1）中的唯一字符串标记（$2），将指定行的内容，修改为字符串（$3）
function modify_config_file(){
    if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
        die 'change_file_line: missing parameter!'
        return
    fi
    echo "change_file_line: \"$1\" \"$2\" \"$3\""
    file_name=$1
    search_tag=$2
    new_content=$3
    tmp=`cat "$file_name" | grep -n "$search_tag" | wc -l`
    if [ "$tmp" == "0" ]; then
        die '[ Error ] find no line!'
        return
    fi
    if [ "$tmp" != "1" ]; then
        die '[ Error ] find more than one line!'
        return
    fi
    line_num=`cat "$file_name" | grep -n "$search_tag" | awk -F':' '{print $1}'`
    echo "modify line: $line_num"
    sed -i "$line_num c $new_content" "$file_name"
}


# 备份指定路径的文件（$1），保存到 .bak 后缀的文件中
fstab_file='/etc/fstab'
sysctl_conf_file='/etc/sysctl.conf'
function backup_file(){
    if [ "$1" == "" ]; then
        die 'backup_file: missing parameter!'
        return
    fi
    echo "backup_file: \"$1\""
    file_name=$1
    new_file="${file_name}.bak"
    if [ ! -f "$new_file" ];then
        cp -f "$file_name" "$new_file"
    fi
}
backup_file "$fstab_file" > '/dev/null' 2>&1
backup_file "$sysctl_conf_file" > '/dev/null' 2>&1


# 设置 /memory_swap 为虚拟内存，大小和物理内存相同
swap_file='/memory_swap'
function set_memory_swap(){
    echo "set_memory_swap"
    mem_size=`free -k | grep 'Mem:' | awk -F' ' '{print $2}'`
    dd if='/dev/zero' of="$swap_file" bs=1024 count=$mem_size
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
    echo 'show `free -m`:'
    free -m
}


# 删除 /memory_swap 的虚拟内存设置
function unset_memory_swap(){
    echo 'unset_memory_swap'
    swapoff "$swap_file"
    rm -rf "$swap_file"
    tmp=`cat "$fstab_file" | grep "$swap_file"`
    if [ "$tmp" != "" ]; then
        new_setting=`cat "$fstab_file" | grep -v "$swap_file"`
        echo $new_setting > "$fstab_file"
    fi
    cat "$fstab_file"
    mount -a
    modify_config_file "$sysctl_conf_file" 'vm.swappiness' 'vm.swappiness=0'
    cat "$sysctl_conf_file" | grep 'vm.swappiness'
    echo 'show `free -m`:'
    free -m
}


# 显示指定目录（$1）的磁盘使用情况
function show_disk_usage(){
    if [ "$1" == "" ]; then
        die 'show_disk_usage: missing parameter!'
        return
    fi
    echo "show_disk_usage: \"$1\""
    dir_name=$1
    if [ ! -d "$dir_name" ];then
        die '[ Error ] not a directory!'
        return
    fi
    echo 'show `df -h`:'
    df -h
    echo 'show `du -h --max-depth=1`:'
    cd "$dir_name"
    du -h --max-depth=1
    cd - > '/dev/null'
}