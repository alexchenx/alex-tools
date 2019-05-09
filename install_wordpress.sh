cd /data/software/
wget https://qooco-software.oss-cn-beijing.aliyuncs.com/wordpress-5.2.tar.gz
tar -zxvf wordpress-5.2.tar.gz
mv wordpress /data/resources/
cd /data/resources/wordpress/
cp wp-config-sample.php wp-config.php
sed -i 's/database_name_here/wordpress/' wp-config.php
sed -i 's/username_here/root/' wp-config.php
sed -i 's/password_here/123456/' wp-config.php
chown -R www.www /data/resources/wordpress/


cat > /data/app/nginx/conf/vhost/wordpress.conf <<EOF
server {
        listen 80;
        server_name localhost;
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
echo "Url: http://${server_ip}/"
echo ""