#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/install/php.sh' | bash

# PHP
# https://github.com/php/php-src





# ———————————————————————— Config ————————————————————————
php_apt_repo_url='https://packages.sury.org/php/'
php_gpg_key_file='/usr/share/keyrings/deb.sury.org-php.gpg'
php_apt_source_file='/etc/apt/sources.list.d/php.list'

php_version='8.4'
php_fpm_service="php${php_version}-fpm"
php_fpm_listen="/run/php/php${php_version}-fpm.sock"
php_extensions='opcache mysql pgsql sqlite3 curl mbstring gd bcmath zip redis memcached yaml xml xsl soap intl imagick gmp bz2'





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist "php${php_version}"
if [ $? -eq 0 ]; then
    log_info 'php already installed, quit now'
    exit 0
fi

wget -O "$php_gpg_key_file" --timeout=120 --no-cache "$php_apt_repo_url/apt.gpg"
if [ $? -ne 0 ]; then
    log_error 'add sury gpg key failed, quit now'
    exit 1
fi
codename=$(get_system_version_codename)
echo "deb [signed-by=$php_gpg_key_file] $php_apt_repo_url $codename main" > "$php_apt_source_file"

php_packages="php${php_version}-cli php${php_version}-fpm"
for php_extension in $php_extensions; do
    php_packages="${php_packages} php${php_version}-${php_extension}"
done

update_software
apt install -y $php_packages
if [ $? -ne 0 ]; then
    log_error 'php packages install failed, quit now'
    exit 1
fi

"php${php_version}" -v | grep --color=never "PHP ${php_version}"
if [ $? -ne 0 ]; then
    log_error 'php install failed, quit now'
    exit 1
fi

systemctl cat "$php_fpm_service"
if [ $? -ne 0 ]; then
    log_error 'php-fpm install failed, quit now'
    exit 1
fi

tmp_file="/tmp/composer-setup_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}.php"
wget -O "$tmp_file" --timeout=120 --no-cache 'https://getcomposer.org/installer'
if [ $? -ne 0 ]; then
    log_error 'composer download failed, quit now'
    exit 1
fi
php "$tmp_file" --install-dir='/usr/local/bin' --filename='composer'
if [ $? -ne 0 ]; then
    log_error 'composer install failed, quit now'
    exit 1
fi
rm -f "$tmp_file"

log_attention "php version: $(php -r 'echo PHP_VERSION;')"
log_attention "php extensions: $(php -m | wc -l)"
log_attention "php fpm service: ${php_fpm_service}"
log_attention "php fastcgi_pass: unix:${php_fpm_listen};"





# ———————————————————————— Start ————————————————————————
systemctl restart "$php_fpm_service"
systemctl enable "$php_fpm_service"
systemctl status --no-pager "$php_fpm_service"

show_tcp_listening
