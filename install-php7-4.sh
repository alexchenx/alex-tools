#!/bin/bash
# Description: Install PHP7.4.33 on CentOS7

yum install -y wget gcc gcc-c++ libxml2 libxml2-devel autoconf make automake libtool re2c bison openssl openssl-devel \
                libpng libpng-devel sqlite-devel libcurl-devel oniguruma-devel libwebp-devel libjpeg-devel
mkdir -p /data/{software,app}

DOWNLOAD_LINK="https://www.php.net/distributions/php-7.4.33.tar.gz"
SHA256SUM="5a2337996f07c8a097e03d46263b5c98d2c8e355227756351421003bea8f463e"

install_php(){
    pkill php-fpm
    [ -d /data/software/php-7.4.33 ] && rm -rf /data/software/php-7.4.33
    [ -d /data/app/php ] && rm -rf /data/app/php
    if [ -f /data/software/php-7.4.33.tar.gz ]; then
        if [ "$(sha256sum /data/software/php-7.4.33.tar.gz | awk '{print $1}')" != "${SHA256SUM}" ]; then
            rm -rf /data/software/php-7.4.33.tar.gz
        fi
    else
        if ! curl -SL "${DOWNLOAD_LINK}" -o /data/software/php-7.4.33.tar.gz; then
            echo "Download failed."
            exit 1
        fi
    fi

    if ! id www; then
        useradd -s /sbin/nologin www
    fi
    cd /data/software/ || exit 1
    tar -zxvf php-7.4.33.tar.gz
    cd php-7.4.33 || exit 1
    if ! ./configure --prefix=/data/app/php \
                --disable-phar \
                --enable-fpm \
                --with-fpm-user=www \
                --with-fpm-group=www \
                --with-mysqli \
                --enable-mbstring \
                --enable-gd \
                --with-webp \
                --with-jpeg \
                --with-freetype \
                --with-curl \
                --with-openssl \
                --with-zlib \
                --enable-bcmath \
                ; then
        echo "configure failed"
        exit 1
    fi
    echo "configure finished."

    if ! make; then
        echo "make failed."
        exit 1
    fi
    echo "make finished."

    if ! make install; then
        echo "make install failed."
        exit 1
    fi
    echo "make install finished."

    cp /data/app/php/etc/php-fpm.conf.default /data/app/php/etc/php-fpm.conf
    cp /data/app/php/etc/php-fpm.d/www.conf.default /data/app/php/etc/php-fpm.d/www.conf
    cp /data/software/php-7.4.33/php.ini-production /data/app/php/lib/php.ini

    echo "Config envionment variables."
    if ! grep -w "/data/app/php/bin/" /etc/profile; then
        echo "export PATH=\$PATH:/data/app/php/bin/" >> /etc/profile
    fi
    source /etc/profile

    echo "Set start when boot server."
    if ! grep "sbin/php-fpm" /etc/rc.local; then
        echo "/data/app/php/sbin/php-fpm" >> /etc/rc.local
    fi
    chmod +x /etc/rc.local

    echo "Start php-fpm"
    /data/app/php/sbin/php-fpm

    echo "Done."
}

install_php