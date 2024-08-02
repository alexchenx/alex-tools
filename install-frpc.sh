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
    echo "设置系统服务..."
    cat > /etc/systemd/system/frpc.service <<EOF
[Unit]
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/frp_${VERSION}_linux_amd64/frpc -c /usr/local/frp_${VERSION}_linux_amd64/frpc.toml

[Install]
WantedBy = multi-user.target
EOF
    systemctl daemon-reload
    echo "设置开机启动..."
    systemctl enable frpc.service
    echo "启动服务..."
    if systemctl start frpc.service; then
        echo "启动成功."
    else
        echo "启动失败!!!"
    fi

    echo """
    使用帮助：
    配置文件地址： /usr/local/frp_${VERSION}_linux_amd64/frpc.toml
    启动frpc服务: systemctl start frpc
    停止frpc服务: systemctl stop frpc
    重启frpc服务: systemctl restart frpc
    查看frpc服务状态: systemctl status frpc
    """
}

uninstall(){
    echo "停止frpc服务"
    systemctl stop frpc.service
    echo "关闭开机启动"
    systemctl disable frpc.service
    echo "删除资源文件"
    rm -rfv /etc/systemd/system/frpc.service
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
