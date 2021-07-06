from terraformpy import Module, Provider, Data
from terraformpy.helpers import relative_file
import os
import yaml

PUBLIC_CIDR="10.1.0.0/24"
PRIVATE_CIDR='10.2.0.0/16'
REGION='us-central1'
OS='rhel-sap-cloud/rhel-7-6-sap-v20210217'
REDIS_DISTRO='https://s3.amazonaws.com/redis-enterprise-software-downloads/6.0.6/redislabs-6.0.6-39-rhel7-x86_64.tar'
BOOT_DISK_SIZE=50
BASTION_MACHINE_TYPE='n1-standard-1'
GCE_SSH_USER='redislabs'
GCE_SSH_PUB_KEY_FILE='~/.ssh/id_rsa.pub'
GCE_SSH_PRIVATE_KEY_FILE='~/.ssh/id_rsa'
REDIS_CLUSTER_NAME='dtest.rlabs.org'
REDIS_USER_NAME='admin@admin.com'
REDIS_PWD='admin'
REDIS_EMAIL_FROM='admin@domain.tld'
REDIS_SMTP_HOST='smtp.domain.tld'
ZONE='us-central1-a'
WORKER_MACHINE_COUNT="8"
WORKER_MACHINE_TYPE = "n1-standard-4"

gcp_provider = Provider("google", project="redislabs-sa-training-services", region=REGION, zone=ZONE, credentials=relative_file("./terraform_account.json"))
#gcp_provider2 = Provider("google", project="redislabs-sa-training-services", region="us-east1", zone="us-east1-b", credentials=relative_file("./terraform_account.json"), alias="alternate")

random_id = Module("random_id", source="./modules/random_id") 

def create_gcp_network(name=None, region=REGION, public_cidr=PUBLIC_CIDR, private_cidr=PRIVATE_CIDR, bastion_zone=ZONE):
    if name is None:
        print("name cannot be None")
        exit(1)

    Provider("google", project="redislabs-sa-training-services", region=region, credentials=relative_file("./terraform_account.json"), alias=name)

    network_mod = Module("network-%s" % name, source="./modules/gcp/network", 
        name= '%s-%s' % (DEPLOYMENT_NAME, name), 
        gce_public_subnet_cidr=public_cidr, 
        region=region, 
        gce_private_subnet_cidr=private_cidr)
    create_gcp_bastion(name, bastion_zone)

def create_gcp_bastion(name, zone):
    inventory = Data("template_file", "inventory-%s" % name,
        template = relative_file("./templates/inventory.tpl"),
        vars = {'worker_host_name': "${join(\"\\n\", module.re-%s.re-nodes.*.name)}" % name}
    )

    extra_vars = Data("template_file", "extra_vars",
        template = relative_file("./templates/extra-vars.tpl"),
        vars = {
            'ansible_user': GCE_SSH_USER,
            'redis_cluster_name': REDIS_CLUSTER_NAME,
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
        os = OS,
        boot_disk_size = BOOT_DISK_SIZE,
        bastion_machine_type = BASTION_MACHINE_TYPE,
        gce_ssh_user = GCE_SSH_USER,
        gce_ssh_pub_key_file = GCE_SSH_PUB_KEY_FILE,
        inventory = '${data.template_file.inventory-%s}' % name,
        extra_vars = '${data.template_file.extra_vars}',
        gce_ssh_private_key_file = GCE_SSH_PRIVATE_KEY_FILE,
        redis_distro = REDIS_DISTRO,
        providers = {"google": "google.%s" % name},
        zone = zone
    )


def create_gcp_cluster(worker_count=WORKER_MACHINE_COUNT, 
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
        source = "./modules/gcp/re",
        name = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        kube_worker_machine_count = worker_count,
        kube_worker_machine_type = machine_type,
        boot_disk_size = BOOT_DISK_SIZE,
        os = OS,
        subnet = '${module.network-%s.private-subnet-name}' % vpc,
        gce_ssh_user = GCE_SSH_USER,
        gce_ssh_pub_key_file = GCE_SSH_PUB_KEY_FILE,
        providers = {"google": "google.%s" % vpc},
        zones = zones
    )

    if expose_ui:
        create_gcp_re_ui(vpc)

def create_gcp_re_ui(vpc):
    if vpc is None:
        print("vpc cannot be None")
        exit(1)

    Module("re-ui-%s" % vpc, source="./modules/gcp/re-ui", 
        name= '%s-%s' % (DEPLOYMENT_NAME, vpc), 
        instances= '${module.re-%s.re-nodes.*.name}' % vpc,
        providers = {"google": "google.%s" % vpc},
        zones = '${module.re-%s.re-nodes.*.zone}' % vpc)

def generate(config_file):
    if 'networks' in config_file:
        for network in config_file['networks']:
            create_gcp_network(**network)
    if 'clusters' in config_file:
        for cluster in config_file['clusters']:
            create_gcp_cluster(**cluster)

if "name" not in os.environ:
    print("Usage: name=xxxx terraformpy where xxxx is the name of this deployment.  used to maintain isolation between deployments")
    exit(1)

DEPLOYMENT_NAME = os.environ["name"]

f = open("config.yaml", "r")
config_file = yaml.load(f, Loader=yaml.FullLoader)
generate(config_file)
