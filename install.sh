#!/bin/bash

echo ">>>>> Welcome to use Alex LNMP install program <<<<<"
echo "0. Install all"
echo "1. Install Mysql"
echo "2. Install php"
echo "3. Install Nginx"
echo "4. Install Wordpress"
echo ""
read -p "Please input number to install: " input_num

case $input_num in
	0)
		source install_mysql.sh
		sh install_php.sh
		sh install_nginx.sh
		sh install_wordpress.sh
	1)
		source install_mysql.sh
	2)
		sh install_php.sh
	3)
		sh install_nginx.sh
	4)
		sh install_wordpress.sh
	*)
		echo "Don't have this option."
esac