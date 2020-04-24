#!/bin/bash

if [ ! -d /data/software/ ]; then
    mkdir -p /data/software/
 fi
 
cd /data/software/
wget http://qooco-software.oss-cn-beijing.aliyuncs.com/jdk/jdk-8u161-linux-x64.tar.gz
tar -zxvf jdk-8u161-linux-x64.tar.gz
mv jdk1.8.0_161/ /data/app/
cd /data/app/
ln -s jdk1.8.0_161/ java

cat >> /etc/profile <<EOF
export JAVA_HOME=/data/app/java/
export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
EOF

echo "Please do two things below:"
echo "1. change securerandom.source=file:/dev/random to securerandom.source=file:/dev/urandom in file /data/app/java/jre/lib/security/java.security line 117"
echo "2. run source /etc/profile"
