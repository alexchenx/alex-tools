#!/bin/bash
# Description: Install Mysql5.7.28 by SourceCode
# Please run by: source ./install-mysql57.sh

yum -y remove mariadb*

yum install -y wget cmake gcc gcc-c++ ncurses-devel bison autoconf openssl openssl-devel

groupadd mysql
useradd -r -g mysql -s /bin/false mysql

mysql_home="/data/app/mysql57"
mysql_default_pwd=`cat /dev/urandom|head -n 10|md5sum|head -c 20`

mkdir -p /data/{software,app}
mkdir -p $mysql_home/data && chown -R mysql.mysql $mysql_home/data/

cd /data/software/
wget http://software.qooco.com/Mysql/mysql-boost-5.7.28.tar.gz
tar -zxvf mysql-boost-5.7.28.tar.gz
cd mysql-5.7.28
cmake -DCMAKE_INSTALL_PREFIX=$mysql_home -DDOWNLOAD_BOOST=1 -DWITH_BOOST=./boost/boost_1_59_0/
make && make install

cat > /etc/my.cnf <<EOF
[client]
port=3306
socket=/tmp/mysql.sock
default-character-set=utf8mb4

[mysqld]
port=3306
socket=/tmp/mysql.sock
key_buffer_size=16M
max_allowed_packet=8M

default-storage-engine=INNODB
character-set-server=utf8mb4
collation-server=utf8mb4_bin

[mysqldump]
quick

EOF

$mysql_home/bin/mysqld --initialize-insecure --user=mysql --basedir=$mysql_home --datadir=$mysql_home/data/

/bin/cp $mysql_home/support-files/mysql.server /etc/init.d/mysqld

echo "Set start when boot server."
echo '/etc/init.d/mysqld start' >> /etc/rc.local
chmod +x /etc/rc.local

echo "Start Mysql start."
/etc/init.d/mysqld start

echo "Config envionment variables."
echo "export PATH=\$PATH:$mysql_home/bin/" >> /etc/profile
source /etc/profile

echo "Set password for mysql root user."
mysql -u root -e "set password for root@'localhost' = password('${mysql_default_pwd}');"

echo "Clean Mysql install directory."
rm -rf /data/software/mysql-boost-5.7.28.tar.gz
rm -rf /data/software/mysql-5.7.28

echo "Done."

echo "Mysql information below:"
echo "---------- Mysql ----------"
echo "Mysql home: $mysql_home"
echo "host: localhost"
echo "username: root"
echo "password: $mysql_default_pwd"
echo ""
echo "Please run: source /etc/profile"
