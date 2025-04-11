#!/bin/bash
# Description: auto install docker-ce on CentOS and Ubuntu.
# Quick install:
# curl -sfL https://raw.githubusercontent.com/alexchenx/alex-tools/master/install-docker.sh | sh -s -- -a install

DOCKER_VERSION="28.0.4"
DOCKER_COMPOSE_VERSION="v2.34.0"

usage() {
    echo "
        Usage: $0 [option] [value]
        Option:
          -h,   --help            Get help information
          -a,   --action        * Require: install or uninstall
          -s,   --source          Install source, cn: download from China, default is from official
          -d,   --data            Specified data-root directory, eg: /data/docker, default is /var/lib/docker
          -v,   --dockerv         docker version, eg: 20.10.17, 20.10.18, default is ${DOCKER_VERSION}
          -c,   --composev        docker-compose version, eg: v2.11.2, default is ${DOCKER_COMPOSE_VERSION}
    "
}

if ! ARGS=$(getopt -a -o a:s:d:v:c: --long action:,source:,data:,dockerv:,composev:,help -- "$@"); then
  echo "Terminating..."
  exit 1
fi

eval set -- "${ARGS}"
while :; do
    case $1 in
    -a | --action)
        ACTION=$2
        shift
        ;;
    -s | --source)
        SOURCE=$2
        shift
        ;;
    -d | --data)
        DATA_ROOT=$2
        shift
        ;;
    -v | --dockerv)
        DOCKER_VERSION=$2
        shift
        ;;
    -c | --composev)
        DOCKER_COMPOSE_VERSION=$2
        shift
        ;;
    --help)
        usage
        exit
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Internal error!"
        exit 1
        ;;
    esac
    shift
done

DOCKER_DOWNLOAD_LINK="https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"
DOCKER_COMPOSE_DOWNLOAD_LINK="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64"
DOCKER_COMPOSE_COMPLETION_DOWNLOAD_LINK="https://raw.githubusercontent.com/docker/compose/refs/heads/v1/contrib/completion/bash/docker-compose"
if [ "${SOURCE}" = "cn" ]; then
    DOCKER_DOWNLOAD_LINK="https://mirrors.aliyun.com/docker-ce/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"
    DOCKER_COMPOSE_DOWNLOAD_LINK="https://software.chenxie.net/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64"
    DOCKER_COMPOSE_COMPLETION_DOWNLOAD_LINK="https://software.chenxie.net/docker-compose/docker-compose_bash_completion_v1"
fi

# Check root
[ "$UID" -ne 0 ] && {
    echo "Must be root run this script."
    exit 1
}

# Load OS info
. /etc/os-release || exit 1

# Check OS
case "${ID}" in
centos|ubuntu)
    ;;
*)
    echo "OS: ${ID}"
    echo "Only support CentOS and Ubuntu."
    exit 1
    ;;
esac

echo_green() {
    msg=$1
    echo -e "\033[32m${msg}\033[0m"
}

echo_red() {
    msg=$1
    echo -e "\033[31m${msg}\033[0m"
}

check_iptables(){
    if ! command -v iptables >/dev/null 2>&1; then
        echo_green "Installing iptables..."
        case "${ID}" in
        ubuntu)
            export NEEDRESTART_MODE="a"
            apt-get update && apt-get install -y --no-install-recommends iptables
            ;;
        centos)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y iptables
            else
                yum install -y iptables
            fi
            ;;
        *)
            echo "OS: ${ID}"
            echo "Only support CentOS and Ubuntu."
            exit 1
            ;;
        esac
    fi
}

check_bash_completion(){
    if [ ! -f /usr/share/bash-completion/bash_completion ] ; then
        echo_green "Installing bash-completion..."
        case "${ID}" in
        ubuntu)
            apt-get update && apt-get install -y --no-install-recommends bash-completion
            ;;
        centos)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y bash-completion
            else
                yum install -y bash-completion
            fi
            ;;
        *)
            echo "Unsupported OS: ${ID}"
            exit 1
            ;;
        esac
    fi
}

install_docker() {
    check_iptables
    if systemctl status docker >/dev/null 2>&1; then
        echo "It looks docker is running, please stop or uninstall it first."
        exit 1
    fi
    echo_green ">>>Install docker..."
    [ -f /tmp/docker-"${DOCKER_VERSION}".tgz ] && rm -rf /tmp/docker-"${DOCKER_VERSION}".tgz
    [ -d /tmp/docker/ ] && rm -rf /tmp/docker

    echo "Download from: $DOCKER_DOWNLOAD_LINK"
    if ! curl -SL "${DOCKER_DOWNLOAD_LINK}" -o /tmp/docker-"${DOCKER_VERSION}".tgz; then
        echo_red "Download failed."
        exit 1
    fi
    tar -zxf /tmp/docker-"${DOCKER_VERSION}".tgz -C /tmp/
    cp /tmp/docker/* /usr/bin/

    [ -n "${DATA_ROOT}" ] && mkdir -p /etc/docker && cat >/etc/docker/daemon.json <<EOF
{
  "data-root": "${DATA_ROOT}"
}
EOF
    cat >/lib/systemd/system/docker.service <<"EOF"
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --default-ulimit nofile=65535:65535
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    if systemctl enable docker --now; then
        echo_green "Docker install successful."
    else
        echo_red "Start docker failed."
        exit 1
    fi
    rm -rf /tmp/docker-"${DOCKER_VERSION}".tgz
    rm -rf /tmp/docker/
}

uninstall_docker() {
    systemctl disable docker --now >/dev/null 2>&1
    rm -rfv /lib/systemd/system/docker.service
    systemctl daemon-reload
    rm -rfv /usr/bin/containerd
    rm -rfv /usr/bin/containerd-shim
    rm -rfv /usr/bin/containerd-shim-runc-v2
    rm -rfv /usr/bin/ctr
    rm -rfv /usr/bin/docker
    rm -rfv /usr/bin/dockerd
    rm -rfv /usr/bin/docker-init
    rm -rfv /usr/bin/docker-proxy
    rm -rfv /usr/bin/runc
    [ -f /etc/docker/daemon.json ] && mv /etc/docker/daemon.json /etc/docker/daemon.json.old_"$(date +%y%m%d%H%M%S)"
    echo "Docker uninstalled."
}

install_docker_compose() {
    echo
    echo_green ">>>Installing docker-compose..."
    [ -f /usr/local/bin/docker-compose ] && rm -rf /usr/local/bin/docker-compose
    echo "Download from: $DOCKER_COMPOSE_DOWNLOAD_LINK"
    if curl -SL "${DOCKER_COMPOSE_DOWNLOAD_LINK}" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1; then
        DOCKER_CONFIG=$HOME/.docker
        mkdir -p "${DOCKER_CONFIG}"/cli-plugins
        cp /usr/local/bin/docker-compose "${DOCKER_CONFIG}"/cli-plugins/
        chmod +x "${DOCKER_CONFIG}"/cli-plugins/docker-compose
        echo_green "docker-compose install successful."
    else
        echo_red "docker-compose install failed."
        exit 1
    fi
}

uninstall_docker_compose() {
    rm -rfv /usr/local/bin/docker-compose
    rm -rfv "${HOME}"/.docker
    echo "docker-compose uninstalled."
}

install_bash_completion() {
    echo
    echo_green ">>>Installing bash completion..."
    check_bash_completion
    # docker
    mkdir -p /etc/bash_completion.d
    docker completion bash > /etc/bash_completion.d/docker
    # docker-compose
    curl -L ${DOCKER_COMPOSE_COMPLETION_DOWNLOAD_LINK} -o /etc/bash_completion.d/docker-compose
    echo_green ">>>Done."
}

uninstall_bash_completion() {
    rm -rfv /etc/bash_completion.d/docker
    rm -rfv /etc/bash_completion.d/docker-compose
}

case "$ACTION" in
install)
    install_docker
    install_docker_compose
    install_bash_completion
    echo
    echo_green "#################### Verify ####################"
    docker -v
    docker-compose version
    echo_green "################################################"
    ;;
uninstall)
    uninstall_docker
    uninstall_docker_compose
    uninstall_bash_completion
    ;;
*)
    usage
    ;;
esac
