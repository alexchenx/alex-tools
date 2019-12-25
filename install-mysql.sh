#!/bin/bash
# Description: Auto install Mysql5.6.44

yum install -y wget cmake gcc gcc-c++ ncurses-devel bison autoconf
mkdir -p /data/{software,app}

mysql_home="/data/app/mysql"
mysql_default_pwd=`cat /dev/urandom|head -n 10|md5sum|head -c 20`

cd /data/software/
useradd -s /sbin/nologin -r mysql
mkdir -p ${mysql_home}/data && chown -R mysql.mysql ${mysql_home}/data/
wget https://qooco-software.oss-cn-beijing.aliyuncs.com/Mysql/mysql-5.6.44.tar.gz
tar -zxvf mysql-5.6.44.tar.gz 
cd mysql-5.6.44
cmake -DCMAKE_INSTALL_PREFIX=${mysql_home}
make && make install
cp ${mysql_home}/support-files/my-default.cnf  /etc/my.cnf
${mysql_home}/scripts/mysql_install_db --user=mysql --basedir=${mysql_home} --datadir=${mysql_home}/data/
cp ${mysql_home}/support-files/mysql.server /etc/init.d/mysqld

echo "Set start when boot server."
echo '/etc/init.d/mysqld start' >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start Mysql start."
/etc/init.d/mysqld start

echo "Config envionment variables."
echo "export PATH=\$PATH:${mysql_home}/bin/" >> /etc/profile
source /etc/profile

echo "Set password for mysql root user."
mysql -u root -e "set password for root@'localhost' = password('${mysql_default_pwd}');"

echo "Done."

echo "Mysql information below:"
echo "---------- Mysql ----------"
echo "Mysql home: ${mysql_home}"
echo "host: localhost"
echo "username: root"
echo "password: ${mysql_default_pwd}"
echo ""
echo "Please run: source /etc/profile"
