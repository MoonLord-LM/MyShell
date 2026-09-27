#!/bin/bash

# wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/prometheus.sh' | bash

# docker rm -f prometheus prometheus_node_exporter prometheus_nginx_exporter prometheus_mysql_exporter prometheus_redis_exporter

# Prometheus
# https://github.com/prometheus/prometheus





# ———————————————————————— Config ————————————————————————
prometheus_container_name='prometheus'
prometheus_image='prom/prometheus:latest'
prometheus_data_dir='/var/lib/prometheus'
prometheus_config_dir='/etc/prometheus'
prometheus_config_file="${prometheus_config_dir}/prometheus.yml"
prometheus_web_config_file="${prometheus_config_dir}/prometheus-web.yml"
prometheus_scrape_password_file="${prometheus_config_dir}/prometheus-scrape-password"
prometheus_port=19090
prometheus_uid='65534'
prometheus_user='admin'
prometheus_password="${PROMETHEUS_PASSWORD:-$(head -c 32 '/dev/urandom' | base64 -w 0)}"

node_exporter_container_name='prometheus_node_exporter'
node_exporter_image='prom/node-exporter:latest'
node_exporter_port=19100

nginx_exporter_container_name='prometheus_nginx_exporter'
nginx_exporter_image='nginx/nginx-prometheus-exporter:latest'
nginx_exporter_port=19113
nginx_host='host.docker.internal'
nginx_port=80

mysqld_exporter_container_name='prometheus_mysql_exporter'
mysqld_exporter_image='prom/mysqld-exporter:latest'
mysqld_exporter_port=19104
mysqld_exporter_config_file="${prometheus_config_dir}/mysqld-exporter.cnf"
mysqld_exporter_uid='65534'
mysql_host='host.docker.internal'
mysql_port=13306
mysql_user='admin'
mysql_password="${MYSQL_PASSWORD:-}"

redis_exporter_container_name='prometheus_redis_exporter'
redis_exporter_image='oliver006/redis_exporter:latest'
redis_exporter_port=19121
redis_exporter_password_file="${prometheus_config_dir}/redis-exporter-password"
redis_exporter_uid='65534'
redis_host='host.docker.internal'
redis_port=16379
redis_password="${REDIS_PASSWORD:-}"

function prometheus_config_yml(){
    cat <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    basic_auth:
      username: ${prometheus_user}
      password_file: /etc/prometheus/prometheus-scrape-password
    static_configs:
      - targets:
          - localhost:9090
        labels:
          server: "${prometheus_server_name}"
          server_ip: "${prometheus_server_ip}"

  - job_name: node
    static_configs:
      - targets:
          - host.docker.internal:${node_exporter_port}
        labels:
          server: "${prometheus_server_name}"
          server_ip: "${prometheus_server_ip}"

  - job_name: nginx
    static_configs:
      - targets:
          - host.docker.internal:${nginx_exporter_port}
        labels:
          server: "${prometheus_server_name}"
          server_ip: "${prometheus_server_ip}"

  - job_name: mysql
    static_configs:
      - targets:
          - host.docker.internal:${mysqld_exporter_port}
        labels:
          server: "${prometheus_server_name}"
          server_ip: "${prometheus_server_ip}"

  - job_name: redis
    static_configs:
      - targets:
          - host.docker.internal:${redis_exporter_port}
        labels:
          server: "${prometheus_server_name}"
          server_ip: "${prometheus_server_ip}"
EOF
}

function create_secrets_dir(){
    local dir="$1"
    local owner="${2:-root}"

    mkdir -p "$dir"
    local rc=$?
    if [ $rc -ne 0 ]; then
        return $rc
    fi

    chown "${owner}:${owner}" "$dir"
    rc=$?
    if [ $rc -ne 0 ]; then
        return $rc
    fi

    chmod 755 "$dir"
    rc=$?
    if [ $rc -ne 0 ]; then
        return $rc
    fi
    return 0
}

function write_secret_file(){
    local file="$1"
    local content="$2"
    local owner="${3:-root}"

    ( umask 077; printf '%s' "$content" > "$file" )
    local rc=$?
    if [ $rc -ne 0 ]; then
        return $rc
    fi

    chown "${owner}:${owner}" "$file"
    rc=$?
    if [ $rc -ne 0 ]; then
        return $rc
    fi

    chmod 600 "$file"
    rc=$?
    if [ $rc -ne 0 ]; then
        return $rc
    fi
    return 0
}





# ———————————————————————— Init ————————————————————————
source <( wget -O- --timeout=10 --no-cache 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/My.sh' )
prepare_common_command
if [ $? -ne 0 ]; then
    echo -ne '\e[1;31m' && echo 'My.sh: load failed, quit now' && echo -ne '\e[0m'
    exit 1
fi





# ———————————————————————— Install ————————————————————————
check_command_exist 'docker'
if [ $? -ne 0 ]; then
    log_error 'docker not installed, please install docker first'
    exit 1
fi

log_warn 'require $MYSQL_PASSWORD and $REDIS_PASSWORD and $PROMETHEUS_PASSWORD, run these first:'
log_warn 'export MYSQL_PASSWORD="<password>"'
log_warn 'export REDIS_PASSWORD="<password>"'
log_warn 'export PROMETHEUS_PASSWORD="<password>"'

docker_host_ip=$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}' 2>/dev/null)
if [ -z "$docker_host_ip" ]; then
    log_error 'cannot detect docker bridge gateway, quit now'
    exit 1
fi
log_attention "docker host ip: ${docker_host_ip}"

create_secrets_dir "$prometheus_config_dir" "root"
if [ $? -ne 0 ]; then
    log_error 'prometheus config dir create failed, quit now'
    exit 1
fi

prometheus_server_name=$(hostname)
prometheus_server_ip=$(hostname -I | awk '{print $1}')

prometheus_password_hash=$(htpasswd -nbB "$prometheus_user" "$prometheus_password" | cut -d: -f2)
if [ -z "$prometheus_password_hash" ]; then
    log_error 'prometheus password hash generate failed, quit now'
    exit 1
fi
web_config_content="basic_auth_users:
  ${prometheus_user}: ${prometheus_password_hash}
"

backup_file "$prometheus_web_config_file"
write_secret_file "$prometheus_web_config_file" "$web_config_content" "$prometheus_uid"
if [ $? -ne 0 ]; then
    log_error 'prometheus web config file create failed, quit now'
    exit 1
fi
write_secret_file "$prometheus_scrape_password_file" "$prometheus_password" "$prometheus_uid"
if [ $? -ne 0 ]; then
    log_error 'prometheus scrape password file create failed, quit now'
    exit 1
fi

backup_file "$prometheus_config_file"
prometheus_config_yml > "$prometheus_config_file"
if [ $? -ne 0 ]; then
    log_error 'prometheus config file create failed, quit now'
    exit 1
fi
chown "${prometheus_uid}:${prometheus_uid}" "$prometheus_config_file"
chmod 644 "$prometheus_config_file"

if [ ! -d "$prometheus_data_dir" ]; then
    mkdir -p "$prometheus_data_dir"
fi
chown "${prometheus_uid}:${prometheus_uid}" "$prometheus_data_dir"

docker inspect "$prometheus_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$prometheus_image"
    docker run -d \
        --name "$prometheus_container_name" \
        --restart unless-stopped \
        --add-host host.docker.internal:${docker_host_ip} \
        -p "$prometheus_port:9090" \
        -v "$prometheus_config_file:/etc/prometheus/prometheus.yml:ro" \
        -v "$prometheus_web_config_file:/etc/prometheus/prometheus-web.yml:ro" \
        -v "$prometheus_scrape_password_file:/etc/prometheus/prometheus-scrape-password:ro" \
        -v "$prometheus_data_dir:/prometheus" \
        "$prometheus_image" \
        --config.file=/etc/prometheus/prometheus.yml \
        --storage.tsdb.path=/prometheus \
        --web.config.file=/etc/prometheus/prometheus-web.yml
    if [ $? -ne 0 ]; then
        log_error 'prometheus container start failed, skip'
    else
        log_attention "prometheus installed on port $prometheus_port (public, basic auth)"
    fi
else
    log_info 'prometheus container already exists, restart'
    docker restart "$prometheus_container_name"
fi

log_attention "prometheus server name: ${prometheus_server_name}"
log_attention "prometheus server ip: ${prometheus_server_ip}"
log_attention "prometheus server port: ${prometheus_port}"
log_attention "prometheus config dir: ${prometheus_config_dir}"
log_attention "prometheus config file: ${prometheus_config_file}"
log_attention "prometheus web config file: ${prometheus_web_config_file}"
log_attention "prometheus data dir: ${prometheus_data_dir}"
log_attention "prometheus user: ${prometheus_user}"
log_attention "prometheus password: ${prometheus_password}"

prometheus_server_url="http://${prometheus_server_ip}:${prometheus_port}"
log_attention "prometheus server url: ${prometheus_server_url}"

docker inspect "$node_exporter_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$node_exporter_image"
    docker run -d \
        --name "$node_exporter_container_name" \
        --restart unless-stopped \
        -p "${docker_host_ip}:${node_exporter_port}:9100" \
        -v '/:/host:ro,rslave' \
        -v '/proc:/host/proc:ro' \
        -v '/sys:/host/sys:ro' \
        "$node_exporter_image" \
        --path.rootfs=/host
    if [ $? -ne 0 ]; then
        log_error 'node_exporter container start failed, skip'
    else
        log_attention "node_exporter installed on ${docker_host_ip}:${node_exporter_port} (internal only)"
    fi
else
    log_info 'node_exporter container already exists, restart'
    docker restart "$node_exporter_container_name"
fi

docker inspect "$nginx_exporter_container_name" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker pull "$nginx_exporter_image"
    docker run -d \
        --name "$nginx_exporter_container_name" \
        --restart unless-stopped \
        --add-host host.docker.internal:${docker_host_ip} \
        -p "${docker_host_ip}:${nginx_exporter_port}:9113" \
        "$nginx_exporter_image" \
        --nginx.scrape-uri="http://${nginx_host}:${nginx_port}/nginx_status"
    if [ $? -ne 0 ]; then
        log_error 'nginx_exporter container start failed, skip'
    else
        log_attention "nginx_exporter installed on ${docker_host_ip}:${nginx_exporter_port} (internal only)"
    fi
else
    log_info 'nginx_exporter container already exists, restart'
    docker restart "$nginx_exporter_container_name"
fi

if [ -n "$mysql_password" ]; then
    mysql_password_escaped=$(printf '%s' "$mysql_password" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    write_secret_file "$mysqld_exporter_config_file" \
"[client]
user = ${mysql_user}
password = \"${mysql_password_escaped}\"
" \
"$mysqld_exporter_uid"
    if [ $? -ne 0 ]; then
        log_error 'mysqld_exporter config file create failed, skip'
    else
        log_info "mysqld_exporter config file: ${mysqld_exporter_config_file} (mode 600, owner ${mysqld_exporter_uid})"

        docker inspect "$mysqld_exporter_container_name" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            docker pull "$mysqld_exporter_image"
            docker run -d \
                --name "$mysqld_exporter_container_name" \
                --restart unless-stopped \
                --add-host host.docker.internal:${docker_host_ip} \
                -p "${docker_host_ip}:${mysqld_exporter_port}:9104" \
                -v "$mysqld_exporter_config_file:/.my.cnf:ro" \
                "$mysqld_exporter_image" \
                --config.my-cnf="/.my.cnf" \
                --mysqld.address="${mysql_host}:${mysql_port}" \
                --tls.insecure-skip-verify
            if [ $? -ne 0 ]; then
                log_error 'mysqld_exporter container start failed, skip'
            else
                log_attention "mysqld_exporter installed on ${docker_host_ip}:${mysqld_exporter_port} (internal only)"
            fi
        else
            log_info 'mysqld_exporter container already exists, restart'
            docker restart "$mysqld_exporter_container_name"
        fi
    fi
else
    log_warn 'mysql_password is empty, skip mysqld_exporter installation'
    log_info 'To enable mysql_exporter:'
    log_info 'export MYSQL_PASSWORD="<password>"'
    log_info 'wget -O- --timeout=10 --no-cache https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/prometheus.sh | bash'
fi

if [ -n "$redis_password" ]; then
    redis_password_escaped=$(printf '%s' "$redis_password" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    write_secret_file "$redis_exporter_password_file" \
"{\"redis://${redis_host}:${redis_port}\": \"${redis_password_escaped}\"}" \
"$redis_exporter_uid"
    if [ $? -ne 0 ]; then
        log_error 'redis_exporter password file create failed, skip'
    else
        log_info "redis_exporter password file: ${redis_exporter_password_file} (mode 600, owner ${redis_exporter_uid})"

        docker inspect "$redis_exporter_container_name" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            docker pull "$redis_exporter_image"
            docker run -d \
                --name "$redis_exporter_container_name" \
                --restart unless-stopped \
                --add-host host.docker.internal:${docker_host_ip} \
                -p "${docker_host_ip}:${redis_exporter_port}:9121" \
                -v "$redis_exporter_password_file:/run/secrets/redis_password:ro" \
                "$redis_exporter_image" \
                --redis.addr="redis://${redis_host}:${redis_port}" \
                --redis.password-file="/run/secrets/redis_password"
            if [ $? -ne 0 ]; then
                log_error 'redis_exporter container start failed, skip'
            else
                log_attention "redis_exporter installed on ${docker_host_ip}:${redis_exporter_port} (internal only)"
            fi
        else
            log_info 'redis_exporter container already exists, restart'
            docker restart "$redis_exporter_container_name"
        fi
    fi
else
    log_warn 'redis_password is empty, skip redis_exporter installation'
    log_info 'To enable redis_exporter:'
    log_info 'export REDIS_PASSWORD="<password>"'
    log_info 'wget -O- --timeout=10 --no-cache https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/bash/docker/prometheus.sh | bash'
fi





# ———————————————————————— Start ————————————————————————
show_tcp_listening

log_info 'docker images:' && docker images
log_info 'docker ps -a:' && docker ps -a
