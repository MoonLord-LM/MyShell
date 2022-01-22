# 将程序（$1）加入 /etc/rc.d/rc.local 配置文件中，设置开机启动
rc_local_file='/etc/rc.d/rc.local'
function set_autorun(){
    check_parameter "$1" || return 1
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
    check_parameter "$1" || return 1
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


# 搜索文件（$1）中的唯一字符串标记（$2），将指定行的内容，修改为字符串（$3）
function modify_config_file(){
    check_parameter "$1" "$2" "$3" || return 1
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
        log_error "find more than one line config in \"file_name\"!"
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
    if [ "$1" == '' ]; then
        log_error 'show_disk_usage: missing parameter!'
        return 1
    fi
    info "show_disk_usage: \"$1\""
    dir=$1
    if [ ! -d "$dir" ]; then
        log_error "\"$dir\" is not a directory!"
        return 1
    fi
    notice 'show `df -h | grep -v '"'"'tmpfs'"'"'`:'
    df -h | grep -v 'tmpfs'
    notice 'show `du -h --max-depth=1`:'
    cd "$dir"
    du -h --max-depth=1
    cd - > '/dev/null'
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
    df -h | grep '/dev/' | grep -v 'tmpfs'
    echo
    netstat -atnlp | grep 'LISTEN'
    echo
}