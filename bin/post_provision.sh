#!/bin/bash
################################################################################
# This script is configuring the bastion node so that it finally runs the
# Ansible playbooks to install Redis Software and configure the Redis cluster
# on the Redis cluster machines
################################################################################

set -x

# Find out the distribution
function get_distro {
  if [ -f /etc/os-release ]; then
      . /etc/os-release
      DISTRO=$NAME
      RELEASE=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
      DISTRO=$(lsb_release -si)
      RELEASE=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
      . /etc/lsb-release
      DISTRO=$DISTRIB_ID
      RELEASE=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
      DISTRO=Debian
      RELEASE=$(cat /etc/debian_version)
  else
      DISTRO="unknown"
      RELEASE="unknown"
  fi
  echo "OS Flavor is $DISTRO"
  echo "OS Release is $RELEASE"
}

# Redhat Family
function deploy_redhat {
if [[ $RELEASE =~ (^[0-9]{1,3}).([0-9]{1,3}) ]]
then
    OS_MAJOR=${BASH_REMATCH[1]} 
    OS_MINOR=${BASH_REMATCH[2]} 
else
    echo Release version $RELEASE not in expcted format
    exit 1
fi

sudo yum -y update --nogpgcheck
sudo yum install -y git wget --nogpgcheck
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_MAJOR}.noarch.rpm || exit 1
sudo yum install -y --nogpgcheck epel-release-latest-${OS_MAJOR}.noarch.rpm
sudo yum install -y --enablerepo="*epel*" ansible
mkdir redis-ansible/
wget -O redis-ansible.tar.gz https://storage.googleapis.com/ps-redis-ansible/redis-ansible-a.1.2.tar.gz
tar -xf redis-ansible.tar.gz -C redis-ansible/ || exit 1
mv boa-inventory.ini redis-ansible/inventories/boa-cluster.ini || exit 1
mv boa-extra-vars.yaml redis-ansible/extra_vars/boa-extra-vars.yaml || exit 1
export ANSIBLE_HOST_KEY_CHECKING=False
cd redis-ansible
ansible-playbook -i ./inventories/boa-cluster.ini redislabs-install.yaml \
                 -e @./extra_vars/boa-extra-vars.yaml \
                 -e @./group_vars/all/main.yaml \
                 -e re_url=$1 \
                 || exit 1
ansible-playbook -i ./inventories/boa-cluster.ini redislabs-create-cluster.yaml \
                 -e @./extra_vars/boa-extra-vars.yaml \
                 -e @./group_vars/all/main.yaml \
                 || exit 1
}

# Here is the main program

# Find out what distribution we're running on
get_distro

# Run the correct deployment function
[[ $DISTRO != unknown ]] || exit 1
[[ $DISTRO =~ Red[[:space:]]Hat[[:space:]]Enterprise[[:space:]]Linux* ]] && deploy_redhat $1
[[ $DISTRO =~ CentOS* ]] && deploy_redhat $1

exit 0
