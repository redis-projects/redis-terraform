from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
import os
import yaml
from . import PUBLIC_CIDR, PRIVATE_CIDR, REGION, OS, REDIS_DISTRO, BOOT_DISK_SIZE, BASTION_MACHINE_TYPE, SSH_USER, SSH_PUB_KEY_FILE, SSH_PRIVATE_KEY_FILE, REDIS_CLUSTER_NAME, REDIS_PWD, REDIS_EMAIL_FROM, REDIS_SMTP_HOST, ZONE, WORKER_MACHINE_COUNT, WORKER_MACHINE_TYPE, REDIS_USER_NAME, DEPLOYMENT_NAME


#TODO: is this needed
#random_id = Module("random_id", source="./modules/random_id") 

def create_network(name=None, region=REGION, public_cidr=PUBLIC_CIDR, private_cidr=PRIVATE_CIDR, 
                  bastion_zone=ZONE, bastion_machine_image=OS, redis_distro=REDIS_DISTRO,
                  bastion_machine_type=BASTION_MACHINE_TYPE, rack_aware=False,
                  redis_cluster_name=REDIS_CLUSTER_NAME):
    if name is None:
        print("name cannot be None")
        exit(1)

    Provider("google", project="redislabs-sa-training-services", region=region, credentials=relative_file("../terraform_account.json"), alias=name)
    Provider("google-beta", project="redislabs-sa-training-services", region=region, credentials=relative_file("../terraform_account.json"), alias=name)

    network_mod = Module("network-%s" % name, source="./modules/gcp/network", 
        name= '%s-%s' % (DEPLOYMENT_NAME, name), 
        gce_public_subnet_cidr=public_cidr, 
        region=region, 
        gce_private_subnet_cidr=private_cidr)
    create_bastion(name, bastion_zone, rack_aware, bastion_machine_type, bastion_machine_image, redis_distro,
                  redis_cluster_name)

def create_bastion(name, zone, rack_aware, machine_type, machine_image, redis_distro, redis_cluster_name):
    inventory = Data("template_file", "inventory-%s" % name,
        template = relative_file("../templates/inventory.tpl"),
        vars = {
            'ip_addrs': "${join(\",\", module.re-%s.re-nodes.*.name)}" % name,
            'rack_ids': "${join(\",\", module.re-%s.re-nodes.*.zone)}" % name if rack_aware else ""
        }
    )

    active_active_script = Data("template_file", "aa_db",
        template = relative_file("../templates/create_aa_db.tpl"),
        vars = {
            'redis_user_name': REDIS_USER_NAME,
            'redis_pwd': REDIS_PWD,
            'redis_cluster_name': REDIS_CLUSTER_NAME,
            'FQDN1': 'domain1.test.net',
            'FQDN2': 'domain2.test.net'
        }
    )

    extra_vars = Data("template_file", "extra_vars",
        template = relative_file("../templates/extra-vars.tpl"),
        vars = {
            'ansible_user': SSH_USER,
            'redis_cluster_name': redis_cluster_name,
            'redis_user_name': REDIS_USER_NAME,
            'redis_pwd': REDIS_PWD,
            'redis_email_from': REDIS_EMAIL_FROM,
            'redis_smtp_host': REDIS_SMTP_HOST
        }
    )   

    bastion_mod = Module("bastion-%s" % name, 
        source = "./modules/gcp/bastion",
        vpc = DEPLOYMENT_NAME,
        random_id = name,
        gce_public_subnet_cidr = PUBLIC_CIDR,
        gce_private_subnet_cidr = PRIVATE_CIDR, 
        region = REGION,
        subnet = '${module.network-%s.public-subnet-name}' % name,
        os = machine_image,
        boot_disk_size = BOOT_DISK_SIZE,
        bastion_machine_type = machine_type,
        gce_ssh_user = SSH_USER,
        gce_ssh_pub_key_file = SSH_PUB_KEY_FILE,
        inventory = '${data.template_file.inventory-%s}' % name,
        active_active_script = '${data.template_file.aa_db}',
        extra_vars = '${data.template_file.extra_vars}',
        gce_ssh_private_key_file = SSH_PRIVATE_KEY_FILE,
        redis_distro = redis_distro,
        providers = {"google": "google.%s" % name},
        zone = zone
    )

    Output("gcp-bastion-%s-ip-output" % name,
            value = "${module.bastion-%s.bastion-public-ip.address}" % name)

def create_re_cluster(worker_count=WORKER_MACHINE_COUNT, 
                            machine_type=WORKER_MACHINE_TYPE,
                            machine_image=OS,
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
        source = "./modules/gcp/re",
        name = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        kube_worker_machine_count = worker_count,
        kube_worker_machine_type = machine_type,
        boot_disk_size = BOOT_DISK_SIZE,
        kube_worker_machine_image =  machine_image,
        subnet = '${module.network-%s.private-subnet-name}' % vpc,
        gce_ssh_user = SSH_USER,
        gce_ssh_pub_key_file = SSH_PUB_KEY_FILE,
        providers = {"google": "google.%s" % vpc},
        zones = zones
    )

    if expose_ui:
        create_re_ui(vpc)

def create_re_ui(vpc):
    if vpc is None:
        print("vpc cannot be None")
        exit(1)

    Module("re-ui-%s" % vpc, source="./modules/gcp/re-ui", 
        name= '%s-%s' % (DEPLOYMENT_NAME, vpc), 
        instances= '${module.re-%s.re-nodes.*.name}' % vpc,
        providers = {"google": "google.%s" % vpc},
        zones = '${module.re-%s.re-nodes.*.zone}' % vpc)


    Output("gcp-re-ui-%s-ip-output" % vpc,
            value = '${module.re-ui-%s.ui-ip.address}' % vpc)

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
        source = "./modules/gcp/ns",
        name = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        providers = {"google-beta": "google-beta.%s" % vpc},
        cluster_fqdn=cluster_fqdn,
        parent_zone=parent_zone,
        ip_addresses = '${module.re-%s.re-public-ips}' % vpc
    )

    Output("%s-dns-name" % vpc,
        value = cluster_fqdn)
