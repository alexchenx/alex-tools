#!/bin/bash
# Description: Install Nginx

yum -y install gcc pcre-devel openssl openssl-devel make
mkdir -p /data/{software,app}

cd /data/software/
useradd -s /sbin/nologin -r www
wget http://nginx.org/download/nginx-1.18.0.tar.gz
tar -zxvf nginx-1.18.0.tar.gz && cd nginx-1.18.0
./configure --prefix=/data/app/nginx --with-http_ssl_module --with-http_stub_status_module --with-http_v2_module
make && make install

cat > /data/app/nginx/conf/nginx.conf << EOF
#
user www;
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
 
    log_format  main escape=json '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for" '
                      '"\$request_body" "\$upstream_addr" \$request_time \$upstream_response_time';
 
    access_log  logs/access.log  main;
 
    include vhost/*.conf;
}
EOF

mkdir /data/app/nginx/conf/vhost
cat > /data/app/nginx/conf/vhost/proxy.conf <<EOF
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

cat > /data/app/nginx/conf/vhost/proxy.conf <<EOF
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
proxy_set_header Host \$host;
proxy_set_header  X-Real-IP  \$remote_addr;
proxy_set_header   X-Forwarded-For  \$proxy_add_x_forwarded_for;
EOF

echo "Set start when boot server."
echo '/data/app/nginx/sbin/nginx' >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start nginx service."
/data/app/nginx/sbin/nginx

echo "Done."



