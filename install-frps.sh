#!/bin/bash

VERSION="0.59.0"
DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${VERSION}/frp_${VERSION}_linux_amd64.tar.gz"

install(){
    cd /tmp/ || exit
    echo "下载安装包..."
    curl -SL ${DOWNLOAD_URL} -o frp_${VERSION}_linux_amd64.tar.gz
    echo "安装中..."
    tar -zxvf frp_${VERSION}_linux_amd64.tar.gz -C /usr/local/
    echo "清理安装包..."
    rm -rfv frp_${VERSION}_linux_amd64.tar.gz
    echo "设置配置文件..."
    cat > /usr/local/frp_${VERSION}_linux_amd64/frps.toml <<EOF
# 监听端口
bindPort = 7000
# 身份验证
auth.token = "ry00JmUuNclD7cIkSEWW"
# 设置http及https协议下代理端口
vhostHTTPPort = 7080
vhostHTTPSPort = 7443
# dashboard 端口以及用户名密码
webServer.addr = "0.0.0.0"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "password"
EOF
    echo "设置系统服务..."
    cat > /etc/systemd/system/frps.service <<EOF
[Unit]
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/frp_${VERSION}_linux_amd64/frps -c /usr/local/frp_${VERSION}_linux_amd64/frps.toml

[Install]
WantedBy = multi-user.target
EOF
    systemctl daemon-reload
    echo "设置开机启动..."
    systemctl enable frps.service
    echo "启动服务..."
    if systemctl start frps.service; then
        echo "启动成功."
    else
        echo "启动失败!!!"
    fi

    echo """
    使用帮助：
    配置文件地址： /usr/local/frp_${VERSION}_linux_amd64/frps.toml
    启动frps服务: systemctl start frps
    停止frps服务: systemctl stop frps
    重启frps服务: systemctl restart frps
    查看frps服务状态: systemctl status frps
    """
}

uninstall(){
    echo "停止frps服务"
    systemctl stop frps.service
    echo "关闭开机启动"
    systemctl disable frps.service
    echo "删除资源文件"
    rm -rfv /etc/systemd/system/frps.service
    systemctl daemon-reload
    rm -rfv  /usr/local/frp_${VERSION}_linux_amd64
    echo "完成"
}

case "$1" in
install)
    install
    ;;
uninstall)
    uninstall
    ;;
*)
    echo "Usage: $0 [ install | uninstall ]"
esac
