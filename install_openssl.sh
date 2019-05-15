#!/bin/bash
# Description: install openssl 1.1.1b

if [[ $(openssl version) =~ '1.1.1b' ]]; then
        echo "openssl is newest now, don't need to install again."
        echo "current openssl version is: $(openssl version)"
        exit
fi


echo "current openssl version is: $(openssl version)"
mkdir -p /data/{software,app}
cd /data/software/

if [ -f /data/software/openssl-1.1.1b.tar.gz ]; then
        echo "/data/software/openssl-1.1.1b.tar.gz is exist, delete it."
        rm -rf /data/software/openssl-1.1.1b.tar.gz
fi
if [ -d /data/software/openssl-1.1.1b ]; then
        echo "/data/software/openssl-1.1.1b is exist, delete it."
        rm -rf /data/software/openssl-1.1.1b
fi
if [ -d /data/app/openssl ]; then
        echo "/data/app/openssl is exist, delete it."
        rm -rf /data/app/openssl
fi

wget https://qooco-software.oss-cn-beijing.aliyuncs.com/openssl-1.1.1b.tar.gz
tar -zxvf openssl-1.1.1b.tar.gz
cd openssl-1.1.1b
./config --prefix=/data/app/openssl
make && make install

echo "backup old version"
mv /usr/bin/openssl /usr/bin/openssl.old
mv /usr/include/openssl /usr/include/openssl.old

echo "link to new version"
ln -s /data/app/openssl/bin/openssl /usr/bin/openssl
ln -s /data/app/openssl/include/openssl /usr/include/openssl

echo "link to new version library"
ln -s /data/app/openssl/lib/libssl.so /usr/local/lib64/libssl.so
ln -s /data/app/openssl/lib/libcrypto.so /usr/local/lib64/libcrypto.so

echo "check..."
strings /usr/local/lib64/libssl.so |grep OpenSSL

echo '/data/app/openssl/lib' >> /etc/ld.so.conf
ldconfig -v


echo "Now, openssl version is: $(openssl version)"
echo "Done."