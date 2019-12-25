#!/bin/bash

if [ ! -f /bin/wget ]; then
	yum install wget
fi

tar_name=mongodb-linux-x86_64-rhel70-4.0.14.tgz
dir_name=${tar_name%.*}

mongodb_home=/data/app/mongodb
mkdir -p $mongodb_home/{db,etc,logs}

mkdir -p /data/software && cd /data/software
if [ -f $tar_name ]; then
	rm -rf $tar_name
fi
wget https://fastdl.mongodb.org/linux/$tar_name
if [ $? -eq 0 ]; then
	tar -zxvf $tar_name
	mv $dir_name /data/app/mongodb/
fi

# config
cat > $mongodb_home/etc/mongodb.conf <<EOF
# mongodb config file
bind_ip=127.0.0.1
port=27017
dbpath=$mongodb_home/db
logpath=$mongodb_home/logs/mongodb.log
pidfilepath=$mongodb_home/$dir_name/mongodb.pid
fork=true
logappend=true
#auth=true
EOF

useradd mongod
chown -R mongod.mongod $mongodb_home

echo "export PATH=\$PATH:$mongodb_home/$dir_name/bin" >> /etc/profile

cat >> /etc/security/limits.conf <<EOF
mongod soft nofile 65535
mongod hard nofile 65535
mongod soft nproc 33000
mongod hard nproc 33000
EOF

mkdir -p /data/scripts
cat > /data/scripts/mongodb.sh << EOF
#!/bin/bash
 
mongo_home=$mongodb_home/$dir_name
mongo_config=$mongodb_home/etc/mongodb.conf
mongo_pid=$mongodb_home/mongodb.pid
 
start() {
        echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
        echo "never" > /sys/kernel/mm/transparent_hugepage/defrag
        su - mongod -c "$mongodb_home/$dir_name/bin/mongod -f $mongodb_home/etc/mongodb.conf"
}
 
stop() {
        ps aux|grep $dir_name|grep -v grep|awk '{print \$2}' | xargs kill -2
}

log() {
	tail -20f $mongodb_home/logs/mongodb.log
}
 
case "\$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart)
                stop
                sleep 3
                start
                ;;
	log)
		log
		;;
        *)
                echo $"Usage: \$0 {start|stop|restart|log}"
                exit 2
esac
EOF

chmod +x /data/scripts/mongodb.sh

source /etc/profile
echo "Start mongodb..."
/data/scripts/mongodb.sh start

echo ""
/data/scripts/mongodb.sh *
echo ""
