sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo yum -y update
sudo yum install -y git
sudo yum install -y ansible
cd /home/${redis_user}
git clone --branch tune_ups https://github.com/reza-rahim/redis-ansible
mv /home/${redis_user}/boa-inventory.ini /home/${redis_user}/redis-ansible/inventories/boa-cluster.ini
mv /home/${redis_user}/boa-extra-vars.yaml /home/${redis_user}/redis-ansible/extra_vars/boa-extra-vars.yaml