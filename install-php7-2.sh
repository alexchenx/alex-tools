#!/bin/bash
# Description: Install php-7.2.31

yum install -y wget gcc gcc-c++ libxml2 libxml2-devel autoconf openssl openssl-devel libpng libpng-devel sqlite-devel libcurl-devel
mkdir -p /data/{software,app}

# Install curl
cd /data/software/
if [ -f /data/software/curl-7.70.0.tar.gz ]; then
        echo "/data/software/curl-7.70.0.tar.gz is exist, delete it."
        rm -rf /data/software/curl-7.70.0.tar.gz
fi
if [ -d /data/software/curl-7.70.0 ]; then
        echo "/data/software/curl-7.70.0 is exist, delete it."
        rm -rf /data/software/curl-7.70.0
fi
if [ -d /data/app/curl ]; then
        echo "/data/app/curl is exist, delete it."
        rm -rf /data/app/curl
fi
wget http://software.qooco.com/php/curl-7.70.0.tar.gz
tar -zxvf curl-7.70.0.tar.gz
cd curl-7.70.0
./configure --prefix=/data/app/curl
make && make install

if [ $? != 0 ]; then
        echo "curl install failed."
        exit
fi


# Install php
php_home="/data/app/php"

if [ -f /data/software/php-7.2.31.tar.gz ]; then
        echo "/data/software/php-7.2.31.tar.gz is exist, delete it."
        rm -rf /data/software/php-7.2.31.tar.gz
fi
if [ -d /data/software/php-7.2.31 ]; then
        echo "/data/software/php-7.2.31 is exist, delete it."
        rm -rf /data/software/php-7.2.31
fi
if [ -d /data/app/php ]; then
        echo "/data/app/php is exist, delete it."
        rm -rf /data/app/php
fi

id www
if [ $? -ne 0 ]; then
        useradd www
fi
cd /data/software/
wget http://software.qooco.com/php/php-7.2.31.tar.gz
tar -zxvf php-7.2.31.tar.gz
cd php-7.2.31
./configure --prefix=${php_home} --enable-fpm --enable-mysqlnd --enable-pcntl --enable-mbstring --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-zlib --with-openssl --with-gd --with-curl=/data/app/curl
make && make install
if [ $? -ne 0 ]; then
        echo "make && make install failed."
        exit
fi
cp ${php_home}/etc/php-fpm.conf.default ${php_home}/etc/php-fpm.conf 
cp ${php_home}/etc/php-fpm.d/www.conf.default ${php_home}/etc/php-fpm.d/www.conf
cp /data/software/php-7.2.31/php.ini-production ${php_home}/lib/php.ini
sed -i 's/user = nobody/user = www/' ${php_home}/etc/php-fpm.d/www.conf
sed -i 's/group = nobody/group = www/' ${php_home}/etc/php-fpm.d/www.conf

echo "Config envionment variables."
echo "export PATH=\$PATH:${php_home}/bin/" >> /etc/profile
source /etc/profile

echo "Set start when boot server."
echo "${php_home}/sbin/php-fpm" >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start php-fpm"
pkill php-fpm
${php_home}/sbin/php-fpm

echo "Done."
