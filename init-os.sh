#!/bin/bash
# Desciption: This script is to init CentOS when buy a new server on Aliyun.

# Check OS
release_version=`rpm -q centos-release|cut -d- -f3`
if [ $release_version != "7" ]; then
	echo "Current only support CentOS 7"
	exit
fi

# Check root user
if [ $USER != "root" ]; then
	echo "Must be root"
	exit
fi

# Set hostname
read -p "Please set your hostname [$(hostname)]: " name
if [ ! -z $name ]; then
	echo $name > /etc/hostname
	hostname $name
	echo "Set hostname to [$name] done, relogin or reboot make it valid."
fi
