#!/bin/bash
################################################################################
# This script is configuring the bastion node so that it installs docker and
# docker-compose to support services
################################################################################

set -x


sudo yum -y update --nogpgcheck
sudo yum install -y yum-utils --nogpgcheck
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

exit 0
