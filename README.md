# lnmp

## 介绍

一键安装lnmp环境：Mysql, PHP, Nginx



## 使用方式

执行：sh install.sh

也可单独执行每一个脚本

执行 install_mysql.sh 时，需通过 source install_mysql.sh 的方式运行，因为脚本里涉及到修改环境变量。



## 为什么要将几个脚本分开，放在一个文件里不好吗？

考虑到不同的使用场景，分开之后你可以只取其中的某个脚本就行，不用关心其他脚本。

比如：

我现在要在一台机器上装mysql，那么我只取用 install_mysql.sh 即可，其他脚本都不用下载。



可单独使用的脚本：

install_mysql.sh

install_nginx.sh



以下脚本不能单独使用：

install_php.sh 需要依赖mysql

install_wordpress.sh 需要依赖mysql, php, nginx





