#!/bin/bash
# Description: auto install docker-ce on CentOS 7 and Ubuntu 20, 22, 24
# Quick install:
# curl -sfL https://raw.githubusercontent.com/alexchenx/alex-tools/master/install-docker.sh | sh -

DOCKER_VERSION="24.0.7"
DOCKER_COMPOSE_VERSION="v2.24.0"

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

ARGS=$(getopt -a -o a:s:d:v:c: --long action:,source:,data:,dockerv:,composev:,help -- "$@")
if [ "$?" != 0 ]; then
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
DOCKER_COMPOSE_DOWNLOAD_LIKE="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64"
[ "${SOURCE}" = "cn" ] && DOCKER_DOWNLOAD_LINK="https://mirrors.aliyun.com/docker-ce/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"

# Check root
[ "$(whoami)" != "root" ] && {
  echo "Must be root run this script."
  exit 1
}

# Check OS
if [ -f /etc/redhat-release ] && [ "$(grep ' 7.' /etc/redhat-release | grep -iEc 'centos|Red Hat')" -eq 1 ]; then
  os="centos"
elif [ "$(grep 'Ubuntu' /etc/issue | grep -cE '20|22|24')" -eq 1 ]; then
  os="ubuntu"
else
  echo "This script only support CentOS 7 and Ubuntu 20, 22, 24."
  exit 1
fi

green_echo() {
  msg=$1
  echo -e "\033[32m${msg}\033[0m"
}

red_echo() {
  msg=$1
  echo -e "\033[31m${msg}\033[0m"
}

docker_install() {
  if systemctl status docker >/dev/null 2>&1; then
    echo "It looks docker is running, please stop or uninstall it first."
    exit 1
  fi
  green_echo ">>>Install docker..."
  [ -f /tmp/docker-"${DOCKER_VERSION}".tgz ] && rm -rf /tmp/docker-"${DOCKER_VERSION}".tgz
  [ -d /tmp/docker/ ] && rm -rf /tmp/docker

  echo "Downloading..."
  echo "Download from: $DOCKER_DOWNLOAD_LINK"
  if ! curl -SL "${DOCKER_DOWNLOAD_LINK}" -o /tmp/docker-"${DOCKER_VERSION}".tgz; then
    red_echo "Download failed."
    exit 1
  fi

  echo "Installing..."
  tar -zxf /tmp/docker-"${DOCKER_VERSION}".tgz -C /tmp/
  cp /tmp/docker/* /usr/bin/

  [ -n "${DATA_ROOT}" ] && mkdir -p /etc/docker && cat >/etc/docker/daemon.json <<EOF
{
  "data-root": "${DATA_ROOT}"
}
EOF
  mkdir -p /etc/bash_completion.d
  curl -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh
  cat >/lib/systemd/system/docker.service <<EOF
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

  if [ ! -f /usr/sbin/iptables ]; then
    echo "Install iptables..."
    if [ "${os}" = "ubuntu" ]; then
      export NEEDRESTART_MODE="a"
      apt install iptables -y
    else
      yum install -y iptables
    fi
  fi
  if systemctl enable docker --now; then
    green_echo "Docker install successful."
  else
    red_echo "Start docker failed."
    exit 1
  fi
  rm -rf /tmp/docker-"${DOCKER_VERSION}".tgz
  rm -rf /tmp/docker/
}

docker_uninstall() {
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

docker_compose_install() {
  echo ""
  green_echo ">>>Installing docker-compose..."
  [ -f /usr/local/bin/docker-compose ] && rm -rf /usr/local/bin/docker-compose

  echo "Downloading..."
  echo "Download from: $DOCKER_COMPOSE_DOWNLOAD_LIKE"
  if curl -SL "${DOCKER_COMPOSE_DOWNLOAD_LIKE}" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1; then
    green_echo "docker-compose install successful."
  else
    red_echo "docker-compose install failed."
    exit 1
  fi
}

docker_compose_uninstall() {
  rm -rfv /usr/local/bin/docker-compose
  echo "docker-compose uninstalled."
}

case "$ACTION" in
install)
  docker_install
  docker_compose_install
  echo ""
  green_echo "#################### Verify ####################"
  docker -v
  docker-compose version
  green_echo "################################################"
  ;;
uninstall)
  docker_uninstall
  docker_compose_uninstall
  ;;
*)
  usage
  ;;
esac
