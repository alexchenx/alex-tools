#!/bin/bash

echo ">>>>> Welcome to use Alex LNMP install program <<<<<"
echo "0. Install all"
echo "1. Install Mysql"
echo "2. Install php"
echo "3. Install Nginx"
echo "4. Install Wordpress"
echo ""
read -p "Please input number to install: " input_num

if [ $input_num == 0 ]; then
	pwd
	source install_mysql.sh
	./install_php.sh
	./install_nginx.sh
	./install_wordpress.sh
elif [ $input_num == 1 ]; then
	source install_mysql.sh
elif [ $input_num == 2 ]; then
	./install_php.sh
elif [ $input_num == 3 ]; then
	./install_nginx.sh
elif [ $input_num == 4 ]; then
	./install_wordpress.sh
else
	echo "Don't have this option."
fi

