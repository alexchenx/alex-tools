#!/bin/bash
# Description: Auto install Mysql5.6 with source code

yum install -y wget cmake gcc gcc-c++ ncurses-devel bison autoconf
mkdir -p /data/{software,app}

cd /data/software/
useradd -s /sbin/nologin mysql
mkdir -p /data/app/mysql/data && chown -R mysql.mysql /data/app/mysql/data/
wget https://qooco-software.oss-cn-beijing.aliyuncs.com/Mysql/mysql-5.6.44.tar.gz
tar -zxvf mysql-5.6.44.tar.gz 
cd mysql-5.6.44
cmake -DCMAKE_INSTALL_PREFIX=/data/app/mysql/
make && make install
cp /data/app/mysql/support-files/my-default.cnf  /etc/my.cnf
/data/app/mysql/scripts/mysql_install_db --user=mysql --basedir=/data/app/mysql/ --datadir=/data/app/mysql/data/
cp /data/app/mysql/support-files/mysql.server /etc/init.d/mysqld

echo "Set start when boost server."
echo '/etc/init.d/mysqld start' >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start Mysql start."
/etc/init.d/mysqld start

echo "Config envionment variables."
echo 'export PATH=$PATH:/data/app/mysql/bin/' >> /etc/profile
source /etc/profile

echo "Set password for mysql root user."
mysql -u root -e "set password for root@'localhost' = password('123456');"

echo "Done."

echo "Mysql information below:"
echo "---------- Mysql ----------"
echo "Mysql home: /data/app/mysql"
echo "host: localhost"
echo "username: root"
echo "password: 123456"
echo ""