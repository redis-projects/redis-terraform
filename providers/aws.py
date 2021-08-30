from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
import os
import yaml
from . import PUBLIC_CIDR, PRIVATE_CIDR, REGION, OS, AWS_REDIS_DISTRO, BOOT_DISK_SIZE, BASTION_MACHINE_TYPE, SSH_USER, SSH_PUB_KEY_FILE, SSH_PRIVATE_KEY_FILE, REDIS_CLUSTER_NAME, REDIS_PWD, REDIS_EMAIL_FROM, REDIS_SMTP_HOST, ZONE, WORKER_MACHINE_COUNT, WORKER_MACHINE_TYPE, REDIS_USER_NAME, DEPLOYMENT_NAME, AWS_VPC_CIDR, AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_OS, REDIS_USER, AWS_SSH_USER, AWS_BASTION_MACHINE_TYPE


def create_network(name=None, region=REGION, vpc_cidr=AWS_VPC_CIDR, public_cidr=PUBLIC_CIDR, 
                  private_cidr=PRIVATE_CIDR, bastion_zone=ZONE, bastion_machine_image=AWS_OS,
                  bastion_machine_type=AWS_BASTION_MACHINE_TYPE, rack_aware=False, 
                  redis_distro=AWS_REDIS_DISTRO,redis_cluster_name=REDIS_CLUSTER_NAME,
                  peer_request_list=[], peer_accept_list=[], region_map={}, cidr_map={}):
    if name is None:
        print("name cannot be None")
        exit(1)

    #Provider("aws", project="redislabs-sa-training-services", region=region, credentials=relative_file("../terraform_account_aws.json"), alias=name)

    Provider("aws", region=region, access_key=AWS_ACCESS_KEY_ID, secret_key=AWS_SECRET_ACCESS_KEY, alias=name)

    vpc_request_list = ['${module.network-' + s + '.vpc}' for s in peer_request_list]
    vpc_accept_list  = ['${module.network-' + s + '.vpc}' for s in peer_accept_list]

    vpc_conn_index = []
    for s in peer_accept_list:
        vpc_conn_index.append('${module.network-%s.peering-request-ids["%s"]}' % (s,name))

    network_mod = Module("network-%s" % name, source="./modules/aws/network", 
        name= '%s-%s' % (DEPLOYMENT_NAME, name),
        vpc_name= name,
        vpc_cidr=vpc_cidr,
        availability_zone = bastion_zone,
        public_subnet_cidr=public_cidr, 
        providers = {"aws": "aws.%s" % name},
        peer_request_list = peer_request_list,
        peer_accept_list = peer_accept_list,
        vpc_request_list = vpc_request_list,
        vpc_accept_list = vpc_accept_list,
        region_map = region_map,
        cidr_map = cidr_map,
        vpc_conn_index = vpc_conn_index,
        private_subnet_cidr=private_cidr)

    create_bastion(name, bastion_zone, rack_aware, bastion_machine_type, bastion_machine_image, redis_distro,
                  redis_cluster_name)

def create_keypair(name):
    Module("keypair-%s" % name, name="%s-%s-keypair" % (DEPLOYMENT_NAME, name), source="./modules/aws/keypair", ssh_public_key=SSH_PUB_KEY_FILE, providers = {"aws": "aws.%s" % name},)

def create_bastion(name, zone, rack_aware, machine_type, machine_image, redis_distro, redis_cluster_name):
    create_keypair(name)
    
    inventory = Data("template_file", "inventory-%s" % name,
        template = relative_file("../templates/inventory.tpl"),
        vars = {
            'ip_addrs': "${join(\",\", module.re-%s.re-nodes.*.private_ip)}" % name,
            'rack_ids': "${join(\",\", module.re-%s.re-nodes.*.availability_zone)}" % name if rack_aware else ""
        }
    )

    extra_vars = Data("template_file", "extra_vars-"+name,
        template = relative_file("../templates/extra-vars.tpl"),
        vars = {
          'ansible_user': REDIS_USER,
          'redis_cluster_name': redis_cluster_name,
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
        ami = machine_image,
        instance_type = machine_type,
        redis_user = REDIS_USER,
        ssh_user = AWS_SSH_USER,
        ssh_public_key = SSH_PUB_KEY_FILE,
        ssh_key_name = '${module.keypair-%s.key-name}' % name,
        inventory = '${data.template_file.inventory-%s}' % name,
        extra_vars = '${data.template_file.extra_vars-%s}' % name,
        ssh_private_key = SSH_PRIVATE_KEY_FILE,
        redis_distro = redis_distro,
        providers = {"aws": "aws.%s" % name},
        availability_zone = zone,
        security_groups = '${module.network-%s.public-security-groups}' % name
    )

    Output("aws-bastion-%s-ip-output" % name,
            value = "${module.bastion-%s}" % name)


def create_re_cluster(worker_count=WORKER_MACHINE_COUNT, 
                            machine_type=WORKER_MACHINE_TYPE,
                            machine_image=AWS_OS,
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
        ami = machine_image,
        security_groups = '${module.network-%s.private-security-groups}' % (vpc,),
        redis_user = REDIS_USER,
        ssh_public_key = SSH_PUB_KEY_FILE,
        ssh_key_name = '${module.keypair-%s.key-name}' % vpc,
        providers = {"aws": "aws.%s" % vpc},
        zones = zones,
        subnet = '${module.network-%s.private-subnet}' % vpc
    )

    if expose_ui:
        create_re_ui(vpc)

def create_re_ui(vpc):

    if vpc is None:
        print("vpc cannot be None")
        exit(1)

    Module("re-ui-%s" % vpc, source="./modules/aws/re-ui", 
        name      = '%s-%s' % (DEPLOYMENT_NAME, vpc), 
        vpc       = '${module.network-%s.vpc}' % vpc,
        ips       = '${module.re-%s.re-nodes.*.private_ip}' % vpc,
        subnets   = '${module.network-%s.private-subnet.*.id}' % vpc,
        providers = {"aws": "aws.%s" % vpc})

    Output("%s-ui-endpoint" % vpc,
            value = '${module.re-ui-%s.ui-ip}' % vpc)

def create_ns_records(vpc=None,
                      cluster_fqdn=None,
                      parent_zone=None):

    if cluster_fqdn is None:
        print("cluster_fqdn cannot be None")
        exit(1)

    if parent_zone is None:
        print("parent_zone cannot be None")
        exit(1)

    if vpc is None:
        print("vpc cannot be None")
        exit(1)

    Module("ns-%s" % (vpc,),
        source = "./modules/aws/ns",
        name = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        providers = {"aws": "aws.%s" % vpc},
        cluster_fqdn=cluster_fqdn,
        parent_zone=parent_zone,
        ip_addresses = '${module.re-%s.re-public-ips}' % vpc
    )

    Output("%s-dns-name" % vpc,
            value = cluster_fqdn)
