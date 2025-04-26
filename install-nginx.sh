#!/bin/bash
# Description: This script is used for installing nginx on CentOS 7 and Ubuntu 20, 22, 24.
# Quick install:
# curl -sfL https://raw.githubusercontent.com/alexchenx/alex-tools/master/install-nginx.sh | sh -

set -e

NGINX_VERSION="1.28.0"
NGINX_HOME="/data/app/nginx"
NGINX_USER="nginx"
NGINX_SITES_DIR="${NGINX_HOME}/conf/conf.d"

support() {
    echo "Only support CentOS 7 and Ubuntu 20/22/24."
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Must be root run this script."
        exit 1
    fi
}

check_os() {
    OS=""
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
        centos)
            [[ "$VERSION_ID" =~ ^7 ]] || { support; exit 1; }
            OS="centos"
            ;;
        ubuntu)
            [[ "$VERSION_ID" =~ ^(20|22|24) ]] || { support; exit 1; }
            OS="ubuntu"
            ;;
        *)
            echo "OS not support: $ID"
            support
            exit 1
            ;;
        esac
    else
        echo "Unknown OS!"; exit 1
    fi
}

echo_green() {
    msg=$1
    echo -e "\033[32m${msg}\033[0m"
}

echo_red() {
    msg=$1
    echo -e "\033[31m${msg}\033[0m"
}

install_dependencies() {
    echo_green "Installing dependency packages..."
    if [[ "$OS" == "centos" ]]; then
        yum install -y gcc make pcre pcre-devel zlib zlib-devel openssl openssl-devel curl > /dev/null
    elif [[ "$OS" == "ubuntu" ]]; then
        apt-get update > /dev/null
        DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev curl > /dev/null
    fi
}

create_nginx_user() {
    echo_green "Check and create user nginx..."
    id -u ${NGINX_USER} &>/dev/null || useradd -r -M -s /sbin/nologin ${NGINX_USER}
}

download_nginx() {
    echo_green "Download nginx..."
    cd /tmp/ || exit
    rm -rf nginx-${NGINX_VERSION}.tar.gz
    rm -rf nginx-${NGINX_VERSION}
    url="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
    echo "Download from: ${url}"
    curl -SL "${url}" -o "nginx-${NGINX_VERSION}.tar.gz" || { echo_red "Download failed!"; exit 1; }
    tar -zxf nginx-${NGINX_VERSION}.tar.gz
    cd nginx-${NGINX_VERSION}
}

compile_install_nginx() {
    echo_green "Compile and install..."
    [ -d "${NGINX_HOME}" ] && mv "${NGINX_HOME}" "${NGINX_HOME}.old_$(date +%Y%m%d_%H%M)"
    ./configure --prefix=${NGINX_HOME} \
                --user=${NGINX_USER} \
                --group=${NGINX_USER} \
                --with-http_ssl_module \
                --with-http_stub_status_module \
                --with-http_v2_module \
                --with-http_realip_module \
                --with-stream_realip_module \
                --with-http_gzip_static_module \
                --with-http_slice_module \
                --with-threads \
                --with-file-aio \
                --with-stream \
                --with-stream_ssl_module \
                --with-http_auth_request_module \
                --with-stream_ssl_preread_module \
                > /dev/null
    make -j"$(nproc)" > /dev/null
    make install > /dev/null
}

configure_nginx() {
    mkdir -p ${NGINX_SITES_DIR}
    mkdir -p ${NGINX_HOME}/logs
    mkdir -p ${NGINX_HOME}/temp
    rm -rf /usr/sbin/nginx && ln -s ${NGINX_HOME}/sbin/nginx /usr/sbin/nginx
    rm -rf /etc/nginx && ln -s ${NGINX_HOME}/conf /etc/nginx

    echo_green "Setup nginx.conf..."
    cat > ${NGINX_HOME}/conf/nginx.conf <<EOF
user ${NGINX_USER};
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    use epoll;
    worker_connections 10240;
    multi_accept on;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    aio             threads;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    server_tokens off;
    autoindex off;
    server_names_hash_bucket_size 128;

    proxy_http_version 1.1;
    proxy_buffering on;
    proxy_buffer_size 4k;
    proxy_buffers 8 16k;
    proxy_busy_buffers_size 32k;
    proxy_temp_file_write_size 64k;
    proxy_read_timeout 60s;
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;

    gzip on;
    gzip_static on;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript application/xml;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log logs/access.log main;
    error_log logs/error.log warn;

    # Cloudflare IP
    real_ip_header CF-Connecting-IP;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2a06:98c0::/29;
    set_real_ip_from 2c0f:f248::/32;
    real_ip_recursive on;

    include ${NGINX_SITES_DIR}/*.conf;

    server {
        listen 80;
        server_name localhost;

        access_log logs/access.log main;
        error_log  logs/error.log;

        location / {
            root html;
            index index.html;
        }
    }
}

stream {
    log_format proxy '\$remote_addr [\$time_local] \$protocol '
                     '\$status \$bytes_sent \$bytes_received '
                     '\$session_time "\$upstream_addr"';

    access_log logs/stream_access.log proxy;

    include ${NGINX_SITES_DIR}/*.tconf;
}
EOF

    cat > ${NGINX_SITES_DIR}/example-http.conf <<"EOF"
#server {
#    listen 80;
#    server_name api.example.com;
#
#    access_log logs/api.example.com_access.log main;
#    error_log logs/api.example.com_error.log;
#
#    location / {
#        proxy_pass http://127.0.0.1:8080;
#        proxy_set_header Host $host;
#        proxy_set_header X-Real-IP $remote_addr;
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#    }
#}
EOF

    cat > ${NGINX_SITES_DIR}/example-tcp.tconf <<"EOF"
#server {
#    listen 3306;
#    proxy_pass 192.168.1.5:3306;
#}
EOF
}

setup_systemd() {
    echo_green "Setup systemd service..."
    cat > /etc/systemd/system/nginx.service <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=network.target

[Service]
Type=forking
ExecStartPre=${NGINX_HOME}/sbin/nginx -t
ExecStart=${NGINX_HOME}/sbin/nginx
ExecReload=${NGINX_HOME}/sbin/nginx -s reload
ExecStop=${NGINX_HOME}/sbin/nginx -s quit
PIDFile=${NGINX_HOME}/logs/nginx.pid
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable nginx
    systemctl restart nginx
}

clean_up() {
    cd /tmp && rm -rf "nginx-${NGINX_VERSION}" "nginx-${NGINX_VERSION}.tar.gz"
}

verify_nginx_status() {
    systemctl status nginx &>/dev/null
    echo_green "Nginx start successfully, Install Done!"
}

main() {
    check_root
    check_os
    install_dependencies
    create_nginx_user
    download_nginx
    compile_install_nginx
    configure_nginx
    setup_systemd
    verify_nginx_status
    clean_up
}

main "$@"
