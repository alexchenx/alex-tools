#!/bin/bash
# Description: Install Nginx

mkdir -p /data/{software,app}

install_modsecurity(){
    echo "-------------------------------------- Install ModSecurity --------------------------------------"
    yum install -y git wget epel-release
    yum install -y gcc-c++ flex bison yajl yajl-devel curl-devel curl GeoIP-devel doxygen zlib-devel pcre-devel lmdb-devel libxml2-devel ssdeep-devel lua-devel libtool autoconf automake
    cd /data/software
    git clone https://github.com/SpiderLabs/ModSecurity
    cd ModSecurity
    git checkout -b v3/master origin/v3/master
    git submodule init
    git submodule update
    sh build.sh
    ./configure
    make
    make install
}

install_nginx(){
    echo "-------------------------------------- Install Nginx --------------------------------------"
    yum -y install gcc pcre-devel openssl openssl-devel make
    cd /data/software/
    id www > /dev/null 2<&1
    if [ $? -ne 0 ]; then
        useradd -s /sbin/nologin -r www
    fi
    git clone https://github.com/SpiderLabs/ModSecurity-nginx
    wget http://nginx.org/download/nginx-1.16.1.tar.gz
    tar -zxvf nginx-1.16.1.tar.gz && cd nginx-1.16.1
    ./configure --prefix=/data/app/nginx --with-http_ssl_module --with-http_stub_status_module --with-http_v2_module --add-module=/data/software/ModSecurity-nginx
    make && make install
}

config_nginx(){
    echo "-------------------------------------- Config Nginx --------------------------------------"
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

    modsecurity on;
    modsecurity_rules_file /data/app/nginx/conf/modsecurity/modsecurity.conf;
 
    log_format  main escape=json '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for" '
                      '"\$request_body" "\$upstream_addr" \$request_time \$upstream_response_time';
 
    access_log  logs/access.log  main;
 
    include vhost/*.conf;
    
    server {
        listen 80;
        server_name localhost;

        location / {
            root html;
            index index.html;
        }
    }
}
EOF

    mkdir /data/app/nginx/conf/vhost
    cat > /data/app/nginx/conf/vhost/proxy.conf <<EOF
#
server_tokens off;
sendfile on;
tcp_nopush on;
tcp_nodelay on;
keepalive_timeout 65;
server_names_hash_bucket_size 128;
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
}

config_modsecurity(){
    echo "-------------------------------------- Config ModSecurity --------------------------------------"
    mkdir /data/app/nginx/conf/modsecurity
    cp /data/software/ModSecurity/modsecurity.conf-recommended /data/app/nginx/conf/modsecurity/modsecurity.conf
    cp /data/software/ModSecurity/unicode.mapping /data/app/nginx/conf/modsecurity/

    cd /data/software
    wget http://www.modsecurity.cn/download/corerule/owasp-modsecurity-crs-3.3-dev.zip
    unzip owasp-modsecurity-crs-3.3-dev.zip
    cp /data/software/owasp-modsecurity-crs-3.3-dev/crs-setup.conf.example /data/app/nginx/conf/modsecurity/crs-setup.conf
    cp -r /data/software/owasp-modsecurity-crs-3.3-dev/rules /data/app/nginx/conf/modsecurity/

    cd /data/app/nginx/conf/modsecurity/
    mv ./rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example ./rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
    mv ./rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example ./rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' modsecurity.conf
    echo 'Include /data/app/nginx/conf/modsecurity/crs-setup.conf' >> modsecurity.conf
    echo 'Include /data/app/nginx/conf/modsecurity/rules/*.conf' >> modsecurity.conf

}

start_nginx(){
    echo "-------------------------------------- Start Nginx --------------------------------------"
    echo "Set start when boot server."
    echo '/data/app/nginx/sbin/nginx' >> /etc/rc.local
    chmod +x /etc/rc.local

    echo "Start nginx service."
    /data/app/nginx/sbin/nginx
}


# 
cd /data/software
echo "Work directory: `pwd`"
echo "Delete directory if exists: ModSecurity* nginx-1.16.1* owasp-modsecurity-crs-3.3-dev*"

rm -rf ModSecurity* nginx-1.16.1* owasp-modsecurity-crs-3.3-dev*

install_modsecurity
if [ $? -eq 0 ]; then
    install_nginx
    if [ $? -eq 0 ]; then
        config_nginx
        if [ $? -eq 0 ]; then
            config_modsecurity
            if [ $? -eq 0 ]; then
                start_nginx
                if [ $? -eq 0 ]; then
                    echo "-------------------------------------- Done --------------------------------------"
                fi
            fi
        fi
    fi
fi