#!/bin/bash

# OpenJDK
# 开源地址：https://github.com/openjdk
# 在线安装：wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/openjdk.sh' | bash



# 参数设置：



# 加载函数：
source <( wget -O- --timeout=10 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi



# 开始安装：
check_system_is_centos
if [ $? -eq 0 ]; then
    remove_software 'java-1.8.0-openjdk-devel'
    remove_software 'java-11-openjdk-devel'
    remove_software 'java-17-openjdk-devel'
    install_software 'java-1.8.0-openjdk-devel'
    install_software 'java-11-openjdk-devel'
    install_software 'java-17-openjdk-devel'
else
    check_system_is_ubuntu
    if [ $? -eq 0 ]; then
        remove_software 'openjdk-8-jdk'
        remove_software 'openjdk-11-jdk'
        remove_software 'openjdk-17-jdk'
        install_software 'openjdk-8-jdk'
        install_software 'openjdk-11-jdk'
        install_software 'openjdk-17-jdk'
    else
        check_system_is_debian
        if [ $? -eq 0 ]; then
            # Fix Bug
            # E: Unable to locate package openjdk-8-jdk
            check_command_exist 'apt-add-repository' || install_software 'software-properties-common'
            apt-add-repository 'deb http://security.debian.org/debian-security stretch/updates main'
            # Fix End

            remove_software 'openjdk-8-jdk'
            remove_software 'openjdk-11-jdk'
            remove_software 'openjdk-17-jdk'
            install_software 'openjdk-8-jdk'
            install_software 'openjdk-11-jdk'
            install_software 'openjdk-17-jdk'
        else
            log_error 'openjdk install failed, unknown system'
        fi
    fi
fi

log_info 'java -version:' && java -version
log_info 'javac -version:' && javac -version

log_info 'java file path list:' && find / -type f 2> '/dev/null' | grep '/bin/java$'
log_info 'javac file path list:' && find / -type f 2> '/dev/null' | grep '/bin/javac$'

log_info 'update-alternatives --display java:' && update-alternatives --display java | grep -v 'slave'
log_info 'update-alternatives --display javac:' && update-alternatives --display javac | grep -v 'slave'



# 启动服务


