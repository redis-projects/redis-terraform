from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
import os
import yaml
from . import PUBLIC_CIDR, PRIVATE_CIDR, REGION, OS, AWS_REDIS_DISTRO, BOOT_DISK_SIZE, BASTION_MACHINE_TYPE, SSH_USER, SSH_PUB_KEY_FILE, SSH_PRIVATE_KEY_FILE, REDIS_CLUSTER_NAME, REDIS_PWD, REDIS_EMAIL_FROM, REDIS_SMTP_HOST, ZONE, WORKER_MACHINE_COUNT, WORKER_MACHINE_TYPE, REDIS_USER_NAME, DEPLOYMENT_NAME, AWS_VPC_CIDR, AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_OS, REDIS_USER, AWS_SSH_USER, AWS_BASTION_MACHINE_TYPE


def create_network(name=None, region=REGION, vpc_cidr=AWS_VPC_CIDR, public_cidr=PUBLIC_CIDR, private_cidr=PRIVATE_CIDR, bastion_zone=ZONE, rack_aware=False, zone=ZONE):
    if name is None:
        print("name cannot be None")
        exit(1)

    #Provider("aws", project="redislabs-sa-training-services", region=region, credentials=relative_file("../terraform_account_aws.json"), alias=name)

    Provider("aws", region=AWS_REGION, access_key=AWS_ACCESS_KEY_ID, secret_key=AWS_SECRET_ACCESS_KEY, alias=name)

    network_mod = Module("network-%s" % name, source="./modules/aws/network", 
        name= '%s-%s' % (DEPLOYMENT_NAME, name),
        vpc_cidr=vpc_cidr,
        public_subnet_cidr=public_cidr, 
        availability_zone=zone, 
        private_subnet_cidr=private_cidr)
    create_bastion(name, bastion_zone, rack_aware)

def create_keypair(name):
    Module("keypair-%s" % name, name="%s-%s-keypair" % (DEPLOYMENT_NAME, name), source="./modules/aws/keypair", ssh_public_key=SSH_PUB_KEY_FILE)

def create_bastion(name, zone, rack_aware=False):
    create_keypair(name)
    
    inventory = Data("template_file", "inventory-%s" % name,
        template = relative_file("../templates/inventory.tpl"),
        vars = {
            'ip_addrs': "${join(\",\", module.re-%s.re-nodes.*.private_ip)}" % name,
            'rack_ids': "${join(\",\", module.re-%s.re-nodes.*.availability_zone)}" % name if rack_aware else ""
        }
    )

    extra_vars = Data("template_file", "extra_vars",
        template = relative_file("../templates/extra-vars.tpl"),
        vars = {
          'ansible_user': REDIS_USER,
          'redis_cluster_name': REDIS_CLUSTER_NAME,
          'redis_user_name': REDIS_USER_NAME,
          'redis_pwd': REDIS_PWD,
          'redis_email_from': REDIS_EMAIL_FROM,
          'redis_smtp_host': REDIS_SMTP_HOST
        }
    )   

    bastion_mod = Module("bastion-%s" % name, 
        source = "./modules/aws/bastion",
        vpc = '${module.network-%s.vpc}' % name,
        name = "%s-%s" % (DEPLOYMENT_NAME, name),
        #region = REGION,
        subnet = '${module.network-%s.public-subnet}' % name,
        ami = AWS_OS,
        instance_type = AWS_BASTION_MACHINE_TYPE,
        ssh_user = AWS_SSH_USER,
        ssh_key_name = '${module.keypair-%s.key-name}' % name,
        inventory = '${data.template_file.inventory-%s}' % name,
        extra_vars = '${data.template_file.extra_vars}',
        ssh_private_key = SSH_PRIVATE_KEY_FILE,
        redis_distro = AWS_REDIS_DISTRO,
        providers = {"aws": "aws.%s" % name},
        availability_zone = zone,
        security_groups = '${module.network-%s.public-security-groups}' % name
    )

    Output("aws-bastion-%s-ip-output" % name,
            value = "${module.bastion-%s}" % name)


def create_re_cluster(worker_count=WORKER_MACHINE_COUNT, 
                            machine_type=WORKER_MACHINE_TYPE,
                            vpc=None,
                            zones=None,
                            expose_ui=False):
    if zones is None:
        print("zones cannot be None")
        exit(1)

    if vpc is None:
        print("vpc cannot be None")
        exit(1)
    
    Module("re-%s" % (vpc,), 
        source = "./modules/aws/re",
        name = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        worker_count = worker_count,
        instance_type = machine_type,
        ami = 'ami-0747bdcabd34c712a',
        subnet = '${module.network-%s.private-subnet}' % vpc,
        security_groups = '${module.network-%s.private-security-groups}' % (vpc,),
        redis_user = REDIS_USER,
        ssh_public_key = SSH_PUB_KEY_FILE,
        ssh_key_name = '${module.keypair-%s.key-name}' % vpc,
        providers = {"aws": "aws.%s" % vpc},
        zones = zones
    )

    if expose_ui:
        create_re_ui(vpc)

def create_re_ui(vpc):
    raise Exception("create ui not currently supported in aws")

    if vpc is None:
        print("vpc cannot be None")
        exit(1)

    Module("re-ui-%s" % vpc, source="./modules/gcp/re-ui", 
        name= '%s-%s' % (DEPLOYMENT_NAME, vpc), 
        instances= '${module.re-%s.re-nodes.*.tags_all}' % vpc,
        providers = {"aws": "aws.%s" % vpc},
        zones = '${module.re-%s.re-nodes.*.zone}' % vpc)
