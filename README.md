# lnmp项目介绍：
1. 目录结构：
```
# tree -L 1 lnmp/
lnmp/
|-- install_mysql.sh
|-- install_nginx.sh
|-- install_php.sh
|-- install.sh
|-- install_wordpress.sh
`-- README.md
```



2. 项目可安装的软件分别如下：

- mysql-5.6.44.tar.gz
- php-7.3.5.tar.gz
- nginx-1.16.0.tar.gz
- wordpress-5.2.tar.gz




3. 项目特点：

此项目将各个软件安装分别放置在单独的脚本文件中，每个脚本可单独使用，也可通过总的程序入口进行使用。

**为什么要这样呢？**
- 因为我在日常的工作中，并不是每台服务器都是需要相同的环境，有的只需要mysql，有的只需要nginx，这种情况，我就只需要拿我需要的脚本运行安装就可以了，而不用将整个程序下载下来；
- 另外以后有版本升级也可以在各个脚本文件里进行业务实现。



4. 程序使用方式：

- 确保你服务器已经安装了git，没有安装请执行命令进行安装：yum install -y git
- 执行命令将项目克隆到本地：git clone https://github.com/alexchenx/lnmp.git
- 进行lnmp目录，并授予脚本执行权限：cd lnmp && chomd +x install*
- 运行脚本开始安装：./install.sh




5. 可单独使用的脚本：
- install_mysql.sh
- install_php.sh
- install_nginx.sh

  以下脚本不能单独使用：

- install_wordpress.sh 需要所在服务器已经安装php和nginx 可使用。