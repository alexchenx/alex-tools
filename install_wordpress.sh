#!/bin/bash


dbhost="localhost"
dbuser="root"
dbpassword="123456"
dbname="wordpress"

source /etc/profile
echo "Create database."
mysql -h ${dbhost} -u root -p123456 -e "drop database wordpress;"
mysql -h ${dbhost} -u root -p123456 -e "create database wordpress;"

echo "Start install wordpress."
mkdir -p /data/{software,resources}
cd /data/software/
wget https://qooco-software.oss-cn-beijing.aliyuncs.com/wordpress-5.2.tar.gz
tar -zxvf wordpress-5.2.tar.gz
mv wordpress /data/resources/
cd /data/resources/wordpress/
cp wp-config-sample.php wp-config.php
sed -i 's/database_name_here/${dbname}/' wp-config.php
sed -i 's/username_here/${dbuser}/' wp-config.php
sed -i 's/password_here/${dbpassword}/' wp-config.php
chown -R www.www /data/resources/wordpress/

my_ip=`ifconfig |grep inet|head -1|awk '{print $2}'`
website_host="www.chenxie.net"

cat > /data/app/nginx/conf/vhost/wordpress.conf <<EOF
server {
        listen 80;
        server_name ${my_ip};
		
		access_log	logs/${my_ip}_access.log main;
		error_log	logs/${my_ip}_error.log;
		
        root /data/resources/wordpress;
        location / {
                try_files \$uri \$uri/ /index.php;
                index index.php;
        }
        location ~ \.php$ {
                fastcgi_pass   127.0.0.1:9000;
                fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
                include        fastcgi_params;
        }
}
EOF

/data/app/nginx/sbin/nginx -s reload

echo "---------- Website ----------"
echo "Url: http://${my_ip}/"
echo ""
