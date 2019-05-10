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
./configure --prefix=${php_home} --enable-fpm
make && make install
cp ${php_home}/etc/php-fpm.conf.default ${php_home}/etc/php-fpm.conf 
cp ${php_home}/etc/php-fpm.d/www.conf.default ${php_home}/etc/php-fpm.d/www.conf
cp /data/software/php-7.3.5/php.ini-production ${php_home}/lib/php.ini


echo "Install mysqli module."
cd /data/software/php-7.3.5/ext/mysqli
sed -i 's/ext\/mysqlnd\/mysql_float_to_double.h/\/data\/software\/php-7.3.5\/ext\/mysqlnd\/mysql_float_to_double.h/' mysqli_api.c
${php_home}/bin/phpize
./configure --with-php-config=${php_home}/bin/php-config --with-mysqli=${mysql_home}/bin/mysql_config
make && make install
echo 'extension=mysqli.so' >> ${php_home}/lib/php.ini

echo "Install zlib module."
cd /data/software/php-7.3.5/ext/zlib
cp config0.m4 config.m4
${php_home}/bin/phpize
./configure --with-php-config=${php_home}/bin/php-config --with-zlib
make && make install
echo 'extension=zlib.so' >> ${php_home}/lib/php.ini

echo "Set start when boot server."
echo "${php_home}/sbin/php-fpm" >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start php-fpm"
${php_home}/sbin/php-fpm

echo "Done."