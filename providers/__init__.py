import os

AWS_VPC_CIDR="10.0.0.0/16"
PUBLIC_CIDR="10.0.1.0/24"
PRIVATE_CIDR='10.0.2.0/24'
REGION='us-central1'
OS='rhel-8-v20210721'
AWS_OS='ami-00f22f6155d6d92c5'
REDIS_DISTRO='https://s3.amazonaws.com/redis-enterprise-software-downloads/6.0.6/redislabs-6.0.6-39-rhel7-x86_64.tar'
BOOT_DISK_SIZE=50
BASTION_MACHINE_TYPE='n1-standard-1'
AWS_BASTION_MACHINE_TYPE='t2.micro'
SSH_USER='redislabs'
REDIS_USER='redislabs'
SSH_PUB_KEY_FILE='~/.ssh/id_rsa.pub'
SSH_PRIVATE_KEY_FILE='~/.ssh/id_rsa'
REDIS_CLUSTER_NAME='dtest.rlabs.org'
REDIS_USER_NAME='admin@admin.com'
REDIS_PWD='admin'
REDIS_EMAIL_FROM='admin@domain.tld'
REDIS_SMTP_HOST='smtp.domain.tld'
ZONE='us-central1-a'
WORKER_MACHINE_COUNT="8"
WORKER_MACHINE_TYPE = "n1-standard-4"
DEPLOYMENT_NAME = os.environ["name"]
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "")
AWS_REGION = os.getenv("AWS_DEFAULT_REGION", "")
AWS_REDIS_DISTRO = 'https://s3.amazonaws.com/redis-enterprise-software-downloads/6.0.8/redislabs-6.0.8-28-bionic-amd64.tar'

#strange import but allows up to mock since these are now properties on the module we can change whenever
from . import aws, azure, gcp
