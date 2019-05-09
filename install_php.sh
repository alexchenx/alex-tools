yum install -y wget gcc gcc-c++  libxml2 libxml2-devel
mkdir -p /data/{software,app}

cd /data/software/
wget https://qooco-software.oss-cn-beijing.aliyuncs.com/php-7.3.5.tar.gz
tar -zxvf php-7.3.5.tar.gz
cd php-7.3.5
./configure --prefix=/data/app/php --enable-fpm
make && make install
cp /data/app/php/etc/php-fpm.conf.default /data/app/php/etc/php-fpm.conf 
cp /data/app/php/etc/php-fpm.d/www.conf.default /data/app/php/etc/php-fpm.d/www.conf
cp /data/software/php-7.3.5/php.ini-production /data/app/php/lib/php.ini


echo "Install mysqli module."
cd /data/software/php-7.3.5/ext/mysqli
sed -i 's/ext\/mysqlnd\/mysql_float_to_double.h/\/data\/software\/php-7.3.5\/ext\/mysqlnd\/mysql_float_to_double.h/' mysqli_api.c
/data/app/php/bin/phpize
./configure --with-php-config=/data/app/php/bin/php-config --with-mysqli=/data/app/mysql/bin/mysql_config
make && make install
echo 'extension=mysqli.so' >> /data/app/php/lib/php.ini

echo "Install zlib module."
cd /data/software/php-7.3.5/ext/zlib
cp config0.m4 config.m4
/data/app/php/bin/phpize
./configure --with-php-config=/data/app/php/bin/php-config --with-zlib
make && make install
echo 'extension=zlib.so' >> /data/app/php/lib/php.ini

echo "Set start when boot server."
echo '/data/app/php/sbin/php-fpm' >> /etc/rc.local

echo "Start php-fpm"
/data/app/php/sbin/php-fpm

