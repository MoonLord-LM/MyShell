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
