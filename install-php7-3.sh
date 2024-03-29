#!/bin/bash
# Description: Install PHP7.3.24

yum install -y wget gcc gcc-c++ libxml2 libxml2-devel autoconf openssl openssl-devel libpng libpng-devel
mkdir -p /data/{software,app}

install_curl(){
        # Install curl
        cd /data/software/
        if [ -f /data/software/curl-7.70.0.tar.gz ]; then
                echo "/data/software/curl-7.70.0.tar.gz is exist, delete it."
                rm -rf /data/software/curl-7.70.0.tar.gz
        fi
        if [ -d /data/software/curl-7.70.0 ]; then
                echo "/data/software/curl-7.70.0 is exist, delete it."
                rm -rf /data/software/curl-7.70.0
        fi
        if [ -d /data/app/curl ]; then
                echo "/data/app/curl is exist, delete it."
                rm -rf /data/app/curl
        fi
        wget https://curl.haxx.se/download/curl-7.70.0.tar.gz --no-check-certificate
        tar -zxvf curl-7.70.0.tar.gz
        cd curl-7.70.0
        ./configure --prefix=/data/app/curl
        make && make install

        if [ $? != 0 ]; then
                echo "curl install failed."
                exit
        fi
}

install_libzip(){
        ## Install libzip
        cd /data/software/
        yum install -y cmake3
        if [ -f /data/software/libzip-1.7.3.tar.gz ]; then
                rm -rf /data/software/libzip-1.7.3.tar.gz
        fi
        if [ -f /data/software/libzip-1.7.3 ]; then
                rm -rf /data/software/libzip-1.7.3
        fi

        wget https://libzip.org/download/libzip-1.7.3.tar.gz
        tar -zxvf libzip-1.7.3.tar.gz
        cd libzip-1.7.3
        mkdir build
        cd build
        cmake3 ..
        make && make install
        echo -e "/usr/local/lib64\n/usr/local/lib\n/usr/lib\n/usr/lib64" > /etc/ld.so.conf.d/php.conf
        ldconfig -v
}

install_freetype(){
        cd /data/software/
        if [ -f /data/software/freetype-2.9.tar.gz ]; then
                rm -rf /data/software/freetype-2.9.tar.gz
        fi
        if [ -f /data/software/freetype-2.9 ]; then
                rm -rf /data/software/freetype-2.9
        fi
        if [ -f /data/app/freetype2 ]; then
                rm -rf /data/app/freetype2
        fi

        wget https://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.gz
        tar -zxvf freetype-2.9.tar.gz
        cd freetype-2.9
        ./configure --prefix=/data/app/freetype2
        make && make install
}

install_php(){
        # Install php
        php_home="/data/app/php"

        if [ -f /data/software/php-7.3.24.tar.gz ]; then
                echo "/data/software/php-7.3.24.tar.gz is exist, delete it."
                rm -rf /data/software/php-7.3.24.tar.gz
        fi
        if [ -d /data/software/php-7.3.24 ]; then
                echo "/data/software/php-7.3.24 is exist, delete it."
                rm -rf /data/software/php-7.3.24
        fi
        if [ -d /data/app/php ]; then
                echo "/data/app/php is exist, delete it."
                rm -rf /data/app/php
        fi

        id www
        if [ $? -ne 0 ]; then
                useradd www
        fi
        cd /data/software/
        yum install -y freetype-devel
        wget https://www.php.net/distributions/php-7.3.24.tar.gz
        tar -zxvf php-7.3.24.tar.gz
        cd php-7.3.24
        ./configure --prefix=${php_home} --enable-zip --enable-fpm --enable-mysqlnd --enable-mbstring --enable-pcntl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-zlib --with-openssl --with-gd --with-curl=/data/app/curl --with-php-config=/data/app/php/bin/php-config --with-freetype-dir=/data/app/freetype2 --enable-bcmath
        make && make install
        if [ $? -ne 0 ]; then
                echo "make && make install failed."
                exit
        fi
        cp ${php_home}/etc/php-fpm.conf.default ${php_home}/etc/php-fpm.conf 
        cp ${php_home}/etc/php-fpm.d/www.conf.default ${php_home}/etc/php-fpm.d/www.conf
        cp /data/software/php-7.3.24/php.ini-production ${php_home}/lib/php.ini
        sed -i 's/user = nobody/user = www/' ${php_home}/etc/php-fpm.d/www.conf
        sed -i 's/group = nobody/group = www/' ${php_home}/etc/php-fpm.d/www.conf

        echo "Config envionment variables."
        echo "export PATH=\$PATH:${php_home}/bin/" >> /etc/profile
        source /etc/profile

        echo "Set start when boot server."
        echo "${php_home}/sbin/php-fpm" >> /etc/rc.local
        chmod +x /etc/rc.local

        echo "Start php-fpm"
        pkill php-fpm
        ${php_home}/sbin/php-fpm

        echo "Done."
}

install_curl
install_libzip
install_freetype
install_php
