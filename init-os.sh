#!/bin/bash
# Desciption: This script is use for init CentOS when buy a new CentOS7 server on Aliyun.

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

echo "***************************************** 主机名设置 **************************************************"
# Set hostname
read -p "Please set your hostname [$(hostname)]: " name
if [ ! -z $name ]; then
	echo $name > /etc/hostname
	hostname $name
	echo "Set hostname to [$name] done, relogin or reboot make it valid."
fi

echo "***************************************** SSH设置 **************************************************"
echo "设置SSH空闲超时退出时间,可降低未授权用户访问其他用户ssh会话的风险"
sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 600/g' /etc/ssh/sshd_config
sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 2/g' /etc/ssh/sshd_config


echo "***************************************** 密码项设置 **************************************************"
# 以下密码设置规则根据阿里云基线检查要求设置
echo "设置密码失效时间为90天，强制定期修改密码，减少密码被泄漏和猜测风险"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
chage --maxdays 90 root

echo "设置密码修改最小间隔时间为7天，限制密码更改过于频繁"
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/g' /etc/login.defs
chage --mindays 7 root

echo "密码复杂度设置"
sed -i 's/^# minlen.*/minlen=10/g' /etc/security/pwquality.conf
sed -i 's/^# minclass.*/minclass=3/g' /etc/security/pwquality.conf

echo "强制用户不重用最近使用的密码，降低密码猜测攻击风险"
sed -i 's/password    sufficient    pam_unix.so.*/& remember=5/g' /etc/pam.d/password-auth
sed -i 's/password    sufficient    pam_unix.so.*/& remember=5/g' /etc/pam.d/system-auth
