#!/bin/bash
# Description: This script is use for install nginx on CentOS 7 and Ubuntu 20, 22.
# Quick install:
# curl -sfL https://raw.githubusercontent.com/alexchenx/alex-tools/master/install-nginx.sh | sh -

VERSION="1.24.0"
NGINX_HOME="/data/app/nginx"

# Check root
[ "$(whoami)" != "root" ] && {
  echo "Must be root run this script."
  exit 1
}

# Check OS
if [ -f /etc/redhat-release ] && [ "$(grep ' 7.' /etc/redhat-release | grep -iEc 'centos|Red Hat')" -eq 1 ]; then
  os="centos"
elif [ "$(grep 'Ubuntu' /etc/issue | grep -cE '20|22|24')" -eq 1 ]; then
  os="ubuntu"
else
  echo "This script only support CentOS 7 and Ubuntu 20, 22, 24."
  exit 1
fi

len_echo() {
  msg=$1
  printf "[$(date +%T)] %-40s" "${msg}"
}

green_echo() {
  msg=$1
  echo -e "\033[32m${msg}\033[0m"
}

red_echo() {
  msg=$1
  echo -e "\033[31m${msg}\033[0m"
}

# Create group and user
[ "$(grep -c "nginx" /etc/group)" -ge 1 ] || groupadd nginx
[ "$(grep -c "nginx" /etc/passwd)" -ge 1 ] || useradd -s /sbin/nologin -M -g nginx -G root nginx

green_echo ">>>Installing dependency packages... "
case "${os}" in
"centos")
  if ! yum -y install gcc pcre-devel openssl openssl-devel make 1>/dev/null; then
    red_echo "failed."
    exit 1
  fi
  ;;
"ubuntu")
  if export NEEDRESTART_MODE="a" && apt-get update 1>/dev/null && ! apt-get install -y libpcre3 libpcre3-dev libssl-dev 1>/dev/null; then
    red_echo "failed."
    exit 1
  fi
  ;;
esac

download() {
  url="$1"
  filename="$2"
  cd /tmp/ || exit
  [ -f "${filename}" ] && rm -rf "${filename}"
  echo "Download from: ${url}"
  if ! curl -SL "${url}" -o "${filename}"; then
    red_echo "failed."
    exit 1
  fi
}

green_echo ">>>Download nginx-${VERSION} ..."
download "http://nginx.org/download/nginx-${VERSION}.tar.gz" "nginx-${VERSION}.tar.gz"

green_echo ">>>Install nginx..."
cd /tmp/ || exit
[ -d "nginx-${VERSION}" ] && rm -rf nginx-${VERSION}

tar -zxf nginx-${VERSION}.tar.gz && cd nginx-${VERSION} || exit
echo "Doing configure..."
./configure --prefix=${NGINX_HOME} \
            --with-http_ssl_module \
            --with-http_stub_status_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-stream_realip_module

echo "Doing make..."
if ! make >/dev/null 2>&1; then
  red_echo "failed."
  exit 1
fi

echo "Doing make install..."
if ! make install >/dev/null 2>&1; then
  red_echo "failed."
  exit 1
fi

echo "Config nginx..."
[ ! -f /usr/sbin/nginx ] && ln -s ${NGINX_HOME}/sbin/nginx /usr/sbin/nginx
[ ! -d /etc/nginx ] && ln -s ${NGINX_HOME}/conf/ /etc/nginx

cat > ${NGINX_HOME}/conf/nginx.conf << "EOF"
#
user nginx;
worker_processes  auto;
error_log  logs/error.log;

events {
    use epoll;
    worker_connections  65535;
}

worker_rlimit_nofile 102400;

http {
    include       mime.types;
    default_type  application/octet-stream;
    server_names_hash_bucket_size 128;

    log_format  main escape=json '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" '
                      '"$request_body" "$upstream_addr" $request_time $upstream_response_time';

    access_log  logs/access.log  main;

    include vhost/*.conf;

    # cloudflare IP 识别
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
    real_ip_header x-forwarded-for;
}
EOF

[ ! -d ${NGINX_HOME}/conf/vhost ] && mkdir ${NGINX_HOME}/conf/vhost
cat > ${NGINX_HOME}/conf/vhost/default.conf <<"EOF"
#
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
EOF

cat > ${NGINX_HOME}/conf/vhost/proxy.conf <<"EOF"
#
server_tokens off;
sendfile on;
tcp_nopush on;
tcp_nodelay on;
keepalive_timeout 65;
client_header_buffer_size 2k;
client_body_buffer_size 256k;
client_body_in_single_buffer on;
large_client_header_buffers 4 4k;
client_max_body_size 100m;

fastcgi_connect_timeout 300;
fastcgi_send_timeout 300;
fastcgi_read_timeout 300;
fastcgi_buffer_size 128k;
fastcgi_buffers 2 256k;
fastcgi_busy_buffers_size 256k;
fastcgi_temp_file_write_size 256k;
fastcgi_intercept_errors on;

open_file_cache max=204800 inactive=20s;
open_file_cache_min_uses 1;
open_file_cache_valid 30s;

gzip on;
gzip_min_length 1k;
gzip_buffers     4 16k;
gzip_http_version 1.1;
gzip_comp_level 2;
gzip_types text/plain text/xml text/css application/javascript application/json application/font-woff application/x-shockwave-flash image/png image/jpeg image/gif;
gzip_vary on;
gzip_disable "MSIE [1-6]\.";

proxy_connect_timeout   300;
proxy_send_timeout      300;
proxy_read_timeout      300;
proxy_buffer_size      256k;
proxy_buffers          4 256k;
proxy_busy_buffers_size 256k;
proxy_temp_file_write_size 256k;
proxy_buffering off;
proxy_cache off;
proxy_set_header Host $host;
proxy_set_header  X-Real-IP  $remote_addr;
proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
EOF

echo "Config nginx system service..."
cat >/lib/systemd/system/nginx.service <<EOF
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=https://nginx.org/en/docs/
After=network.target nss-lookup.target

[Service]
Restart=always
RestartSec=1
Type=forking
PIDFile=${NGINX_HOME}/logs/nginx.pid
ExecStartPre=${NGINX_HOME}/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=${NGINX_HOME}/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=${NGINX_HOME}/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile ${NGINX_HOME}/logs/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable nginx

echo "Start nginx service..."
if systemctl start nginx; then
    green_echo "Started."
fi
