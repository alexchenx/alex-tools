#!/bin/bash

echo ">>>>> Welcome to Alex LNMP install program <<<<<"
echo "This program can install Mysql, PHP, Nginx, Wordpress"
echo "0. Install All"
echo "1. Install Mysql+PHP+Nginx"
echo "2. Install Mysql"
echo "3. Install PHP"
echo "4. Install OpenSSL"
echo "5. Install Nginx"
echo "6. Install Wordpress"
echo ""
read -p "Please input number to install: " input_num

if [ $input_num == 0 ]; then
	./install_mysql.sh
	./install_php.sh
	./install_nginx.sh
	./install_wordpress.sh
elif [ $input_num == 1 ]; then
	./install_mysql.sh
        ./install_php.sh
        ./install_nginx.sh
elif [ $input_num == 2 ]; then
	./install_mysql.sh
elif [ $input_num == 3 ]; then
	./install_php.sh
elif [ $input_num == 4 ]; then
	./install_openssl.sh
elif [ $input_num == 5 ]; then
	./install_nginx.sh
elif [ $input_num == 6 ]; then
	./install_wordpress.sh
else
	echo "Don't have this option."
fi
echo "Please run command to make envionment variables available: source /etc/profile"
