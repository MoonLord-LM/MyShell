#!/bin/bash
source ./My.sh

# 全部在线安装
# sudo chmod -R 777 ./ && sudo sh ./all.sh --install
# sudo chmod -R 777 ./ && sudo sh ./all.sh --reinstall
# sudo chmod -R 777 ./ && sudo sh ./all.sh --clean_cache


if [ "$1" == "--install" ]; then
    sudo sh ./mysql_5.7.23.sh --install
    sudo sh ./mysql_8.0.12.sh --install
    sudo sh ./php_5.6.37.sh --install
    sudo sh ./nginx_1.15.2.sh --install
    sudo sh ./shadowsocks_2.8.2.sh --install
    sudo sh ./shadowsocks_3.2.0.sh --install
    exit 0
elif [ "$1" == "--reinstall" ]; then
    sudo sh ./mysql_5.7.23.sh --reinstall
    sudo sh ./mysql_8.0.12.sh --reinstall
    sudo sh ./php_5.6.37.sh --reinstall
    sudo sh ./nginx_1.15.2.sh --reinstall
    sudo sh ./shadowsocks_2.8.2.sh --reinstall
    sudo sh ./shadowsocks_3.2.0.sh --reinstall
    exit 0
elif [ "$1" == "--clean_cache" ]; then
    sudo sh ./mysql_5.7.23.sh --clean_cache
    sudo sh ./mysql_8.0.12.sh --clean_cache
    sudo sh ./php_5.6.37.sh --clean_cache
    sudo sh ./nginx_1.15.2.sh --clean_cache
    sudo sh ./shadowsocks_2.8.2.sh --clean_cache
    sudo sh ./shadowsocks_3.2.0.sh --clean_cache
    exit 0
else
    echo && \
    info 'options:' && \
    echo && \
    info "    --install      install all" && \
    info "                   default install dir: /usr/local/" && \
    info '                   if already installed, do nothing' && \
    echo && \
    info "    --reinstall    reinstall all" && \
    info "                   default install dir: /usr/local/" && \
    info '                   delete the existed, and redo installation' && \
    echo && \
    info '    --clean_cache  delete cached files' && \
    info '                   use this to save disk space' && \
    info '                   it will slow down the future installations' && \
    echo && \
    die 'require one option'
    exit 1
fi

show