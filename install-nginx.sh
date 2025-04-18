#!/bin/bash
# Description: This script is use for install nginx on CentOS 7 and Ubuntu 20, 22, 24.
# Quick install:
# curl -sfL https://raw.githubusercontent.com/alexchenx/alex-tools/master/install-nginx.sh | sh -

# set -e 作用: 一旦脚本中的某个命令返回非 0（出错），立即退出整个脚本， 不用再自行判断命令是否执行成功。
set -e

NGINX_VERSION="1.24.0"
NGINX_HOME="/data/app/nginx"
NGINX_USER="nginx"
NGINX_SITES_DIR="${NGINX_HOME}/conf/conf.d"

if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户运行该脚本。"
    exit 1
fi

OS=""
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
    centos)
        [[ "$VERSION_ID" =~ ^7 ]] || { echo "仅支持 CentOS 7"; exit 1; }
        OS="centos"
    ;;
    ubuntu)
        [[ "$VERSION_ID" =~ ^(20|22|24) ]] || { echo "仅支持 Ubuntu 20/22/24"; exit 1; }
        OS="ubuntu"
        ;;
    *)
        echo "不支持的系统: $ID"; exit 1
    ;;
    esac
else
    echo "无法检测操作系统类型"; exit 1
fi

echo_green() {
    msg=$1
    echo -e "\033[32m${msg}\033[0m"
}

echo_red() {
    msg=$1
    echo -e "\033[31m${msg}\033[0m"
}

echo_green "安装依赖..."
if [[ "$OS" == "centos" ]]; then
    yum install -y gcc make pcre pcre-devel zlib zlib-devel openssl openssl-devel curl > /dev/null
elif [[ "$OS" == "ubuntu" ]]; then
    apt-get update > /dev/null
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev curl > /dev/null
fi

echo_green "检查并创建 nginx 用户..."
id -u ${NGINX_USER} &>/dev/null || useradd -r -M -s /sbin/nologin ${NGINX_USER}

echo_green "下载 Nginx..."
cd /tmp/ || exit
rm -rf nginx-${NGINX_VERSION}.tar.gz
rm -rf "nginx-${NGINX_VERSION}"
curl -SL "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o "nginx-${NGINX_VERSION}.tar.gz" || { echo_red "下载失败！"; exit 1; }
tar -zxf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}

echo_green "编译并安装 Nginx..."
[ -d "${NGINX_HOME}" ] && mv "${NGINX_HOME}" "${NGINX_HOME}.old_$(date +%Y%m%d_%H%M)"
echo "Doing configure"
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

echo "Doing make"
make -j"$(nproc)" > /dev/null
echo "Doing make install"
make install > /dev/null

echo_green "配置路径结构..."
mkdir -p ${NGINX_SITES_DIR}
mkdir -p ${NGINX_HOME}/logs
mkdir -p ${NGINX_HOME}/temp

echo_green "配置软链接..."
rm -rf /usr/sbin/nginx && ln -s ${NGINX_HOME}/sbin/nginx /usr/sbin/nginx
rm -rf /etc/nginx && ln -s ${NGINX_HOME}/conf /etc/nginx

echo_green "修改 nginx.conf..."
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

    # Basic Settings
    sendfile        on;
    aio             threads;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    server_tokens off;
    autoindex off;
    server_names_hash_bucket_size 128;

    # 代理性能优化
    proxy_http_version 1.1;
    proxy_buffering on;
    proxy_buffer_size 4k;
    proxy_buffers 8 16k;
    proxy_busy_buffers_size 32k;
    proxy_temp_file_write_size 64k;
    proxy_read_timeout 60s;
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;

    # -------- Gzip 压缩 --------
    gzip on;
    gzip_static on;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript application/xml;

    # 安全 headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";

    # -------- 实时日志格式 --------
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log logs/access.log main;
    error_log logs/error.log warn;

    # -------- Cloudflare IP 支持 --------
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

    # -------- 默认访问页--------
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

# -------- 四层 TCP 代理配置 --------
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

echo_green "设置 systemd 服务..."
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
if systemctl status nginx &>/dev/null; then
    echo "Nginx 启动成功，安装完成！"
    cd /tmp && rm -rf "nginx-${NGINX_VERSION}" "nginx-${NGINX_VERSION}.tar.gz"
else
    echo_red "Nginx 启动失败，请检查日志"
fi
