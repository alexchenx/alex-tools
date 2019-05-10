#!/bin/bash
# Description: Install PHP7.3.5

yum install -y wget gcc gcc-c++ libxml2 libxml2-devel autoconf
mkdir -p /data/{software,app}

php_home="/data/app/php"
mysql_home="/data/app/mysql"

cd /data/software/
wget https://qooco-software.oss-cn-beijing.aliyuncs.com/php-7.3.5.tar.gz
tar -zxvf php-7.3.5.tar.gz
cd php-7.3.5
./configure --prefix=${php_home} --enable-fpm --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-zlib --with-openssl
make && make install
cp ${php_home}/etc/php-fpm.conf.default ${php_home}/etc/php-fpm.conf 
cp ${php_home}/etc/php-fpm.d/www.conf.default ${php_home}/etc/php-fpm.d/www.conf
cp /data/software/php-7.3.5/php.ini-production ${php_home}/lib/php.ini

echo "Set start when boot server."
echo "${php_home}/sbin/php-fpm" >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start php-fpm"
${php_home}/sbin/php-fpm

echo "Done."