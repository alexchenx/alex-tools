#!/bin/bash
# Quick install:
# curl -sfL https://raw.githubusercontent.com/alexchenx/alex-tools/master/init-os.sh | bash -

set -e

support() {
    echo "Only support CentOS 7 and Ubuntu 20/22/24."
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Must be root run this script."
        exit 1
    fi
}

check_os() {
    OS=""
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID}" in
        centos)
            [[ "${VERSION_ID}" =~ ^7 ]] || { support; exit 1; }
            OS="centos"
            ;;
        ubuntu)
            [[ "${VERSION_ID}" =~ ^(20|22|24) ]] || { support; exit 1; }
            OS="ubuntu"
            ;;
        *)
            echo "OS not support: ${ID}"
            support
            exit 1
            ;;
        esac
    else
        echo "Unknown OS!"; exit 1
    fi
}

do_init() {
    echo "####################################### 升级和安装软件包 #########################################"
    case "${OS}" in
    ubuntu)
        # apt -y update && NEEDRESTART_MODE=a apt -y upgrade
        apt -y update && NEEDRESTART_MODE=a apt -y install bash-completion htop iftop iotop vim wget curl xfsprogs nfs-common net-tools iptables iputils-ping
        ;;
    centos)
        # yum -y update
        yum -y install bash-completion htop iftop iotop vim wget curl xfsprogs nfs-utils net-tools iptables iputils-ping
        ;;
    *)
        echo "OS not support."
        exit 1
        ;;
    esac

    echo "####################################### 配置时间显示格式 #########################################"
    hist_time_format="export HISTTIMEFORMAT=\"%Y-%m-%d %H:%M:%S \$(whoami) \""
    if ! grep -qF "${hist_time_format}" /etc/profile; then
        echo "${hist_time_format}" >> /etc/profile
    fi

    echo "####################################### 配置ll别名 #########################################"
    alias_ll="alias ll='ls -lhtr --time-style=long-iso --color'"
    if ! grep -qF "${alias_ll}" ~/.bashrc; then
        echo "${alias_ll}" >> ~/.bashrc
    fi

    echo "####################################### 配置vim #########################################"
    vimrc_file="/etc/vim/vimrc.local"
    touch "${vimrc_file}"
    for setting in "set paste" "set nu"; do
        grep -qxF "$setting" "$vimrc_file" || echo "$setting" >> "$vimrc_file"
    done

    echo "####################################### 配置时区 #########################################"
    timedatectl set-timezone Asia/Shanghai

    echo "！！！ 完成 ！！！"
}

main() {
    check_root
    check_os

    case "${OS}" in
    ubuntu|centos)
        do_init
        ;;
    *)
        echo "OS not support."
        ;;
    esac
}

main "$@"
