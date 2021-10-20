"""
This module is spezific to the Azure cloud and implements the creation of
- networks (Vnets and subnets and peer them)
- the bastion node
- the re-cluster nodes
- the load balancer for the Redis GUI
- the DNS zone changes (adding records)
"""
import sys
from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
from . import PUBLIC_CIDR, PRIVATE_CIDR, REGION, OS, REDIS_DISTRO, \
              BASTION_MACHINE_TYPE, SSH_USER, SSH_PUB_KEY_FILE, SSH_PRIVATE_KEY_FILE, \
              REDIS_CLUSTER_NAME, REDIS_PWD, REDIS_EMAIL_FROM, REDIS_SMTP_HOST, ZONE, \
              WORKER_MACHINE_COUNT, WORKER_MACHINE_TYPE, REDIS_USER_NAME, DEPLOYMENT_NAME

def create_network(name=None, region=REGION, public_cidr=PUBLIC_CIDR, private_cidr=PRIVATE_CIDR,
                  bastion_zone=ZONE, bastion_machine_image=OS, redis_distro=REDIS_DISTRO,
                  bastion_machine_type=BASTION_MACHINE_TYPE, rack_aware=False,
                  redis_cluster_name=REDIS_CLUSTER_NAME, resource_group=None,
                  subscription_id=None, tenant_id=None, application_id=None,
                  client_certificate_path=None, vpc_cidr=None, expose_ui=False,
                  peer_request_list=None, peer_accept_list=None, other_nets=None, fqdn_map=None):
    """
    create_network calls the Terraform 'network' module which is creating the VNETs and their
    subnets. The security groups are generated for the private and public subnets and finally
    the VNETs are peered where requested
    """
    if name is None:
        print("name cannot be None")
        sys.exit(1)
    if subscription_id is None:
        print("For Azure, subscription_id cannot be None")
        sys.exit(1)
    if tenant_id is None:
        print("For Azure, tenant_id cannot be None")
        sys.exit(1)
    if application_id is None:
        print("For Azure, application_id cannot be None")
        sys.exit(1)
    if client_certificate_path is None:
        print("For Azure, client_certificate_path cannot be None")
        sys.exit(1)

    Provider("azurerm", features={}, client_id=application_id, tenant_id=tenant_id,
             subscription_id=subscription_id, client_certificate_path=client_certificate_path,
             alias=name)

    vpc_request_list= []
    vpc_accept_list= []
    if peer_request_list:
        vpc_request_list = ['${module.network-' + s + '.vpc}' for s in peer_request_list]
    if peer_accept_list:
        vpc_accept_list = ['${module.network-' + s + '.vpc}' for s in peer_accept_list]
    if not peer_accept_list:
        peer_accept_list  = []

    Module("network-%s" % name, source="./modules/azure/network",
        name                    = '%s-%s' % (DEPLOYMENT_NAME, name),
        vpc_cidr                = vpc_cidr,
        public_subnet_cidr      = public_cidr,
        private_subnet_cidr     = private_cidr,
        region                  = region,
        resource_group          = resource_group,
        expose_ui               = expose_ui,
        vpc_request_list        = vpc_request_list,
        vpc_accept_list         = vpc_accept_list,
        providers               = {"azurerm": "azurerm.%s" % name})

    create_bastion(name, bastion_zone, rack_aware, bastion_machine_type,bastion_machine_image,
                   redis_distro,redis_cluster_name, region, resource_group)

def create_bastion(name, zone, rack_aware, machine_type, machine_image,
                   redis_distro, redis_cluster_name, region, resource_group):
    """
    create_bastion is setting up the bastion node in the public subnet. It also creates the
    files used by Ansible runs like the inventory and the extra variables
    """

    Data("template_file", "inventory-%s" % name,
        template = relative_file("../templates/inventory.tpl"),
        vars = {
            'ip_addrs': "${join(\",\", module.re-%s.re-nodes.*.private_ip_address)}" % name,
            'rack_ids': "${join(\",\", module.re-%s.re-nodes.*.zone)}" % name if rack_aware else ""
        }
    )

    Data("template_file", "aa_db",
        template = relative_file("../templates/create_aa_db.tpl"),
        vars = {
            'redis_user_name': REDIS_USER_NAME,
            'redis_pwd': REDIS_PWD,
            'redis_cluster_name': REDIS_CLUSTER_NAME,
            'FQDN1': 'domain1.test.net',
            'FQDN2': 'domain2.test.net'
        }
    )

    Data("template_file", "extra_vars-"+name,
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

    Module("bastion-%s" % name,
        source                   = "./modules/azure/bastion",
        name                     = '%s-%s' % (DEPLOYMENT_NAME, name),
        region                   = region,
        resource_group           = resource_group,
        public_subnet_id         = '${module.network-%s.public-subnet}' % name,
        public_secgroup          = '${module.network-%s.public-security-groups}' % name,
        os                       = machine_image,
        bastion_machine_type     = machine_type,
        ssh_user                 = SSH_USER,
        ssh_pub_key_file         = SSH_PUB_KEY_FILE,
        redis_distro             = redis_distro,
        providers                = {"azurerm": "azurerm.%s" % name},
        ssh_private_key_file     = SSH_PRIVATE_KEY_FILE,
        inventory                = '${data.template_file.inventory-%s}' % name,
        extra_vars               = '${data.template_file.extra_vars-%s}' % name,
        active_active_script     = '${data.template_file.aa_db}',
        zone                     = zone
    )

    Output("Azure-bastion-%s-ip-output" % name,
        value = "${module.bastion-%s.bastion-public-ip-address}" % name)

def create_re_cluster(worker_count=WORKER_MACHINE_COUNT,
                      machine_type=WORKER_MACHINE_TYPE,
                      machine_image=OS,vpc=None,
                      zones=None, region_map=None, rg_map=None,
                      expose_ui=False):
    """
    create_re_cluster sets up the Redis Enterprise cluster. Those nodes are created in the
    private subnet
    """
    if zones is None:
        print("zones cannot be None")
        sys.exit(1)

    if vpc is None:
        print("vpc cannot be None")
        sys.exit(1)

    Module("re-%s" % (vpc,),
        source            = "./modules/azure/re",
        name              = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        machine_count     = worker_count,
        machine_type      = machine_type,
        os                =  machine_image,
        private_subnet_id = '${module.network-%s.private-subnet}' % vpc,
        private_secgroup  = '${module.network-%s.private-security-groups}' % vpc,
        ssh_user          = SSH_USER,
        ssh_pub_key_file  = SSH_PUB_KEY_FILE,
        providers         = {"azurerm": "azurerm.%s" % vpc},
        zones             = zones,
        region            = region_map[vpc],
        resource_group    = rg_map[vpc]
    )

    if expose_ui:
        create_re_ui(vpc, region_map[vpc], rg_map[vpc])

def create_re_ui(vpc, region, resource_group):
    """
    create_re_ui create a network load balancer with a public frontend IP and the Redis cluster
    nodes as a backend pool (using private IPs). The sessions are sticky
    """
    if vpc is None:
        print("vpc cannot be None")
        sys.exit(1)

    Module("re-ui-%s" % vpc,
        source            = "./modules/azure/re-ui",
        name              = '%s-%s' % (DEPLOYMENT_NAME, vpc),
        instances         = '${module.re-%s.re-nodes.*.private_ip_address}' % vpc,
        providers         = {"azurerm": "azurerm.%s" % vpc},
        vnet              = '${module.network-%s.vpc}' % vpc,
        region            = region,
        resource_group    = resource_group
    )


    Output("re-ui-%s-ip-output" % vpc,
            value = '${module.re-ui-%s.ui-ip}' % vpc)

def create_ns_records(vpc          = None,
                      cluster_fqdn = None,
                      parent_zone  = None,
                      rg_map       = None):
    """
    create_ns_records is responsible for teh DNS setup in Azure. It creates the
    three A-records and the NS record for the cluster
    """

    if cluster_fqdn is None:
        print("cluster_fqdn cannot be None")
        sys.exit(1)

    if parent_zone is None:
        print("parent_zone cannot be None")
        sys.exit(1)

    if vpc is None:
        print("vpc cannot be None")
        sys.exit(1)

    Module("ns-%s" % (vpc,),
        source         = "./modules/azure/ns",
        providers      = {"azurerm": "azurerm.%s" % vpc},
        cluster_fqdn   = cluster_fqdn,
        parent_zone    = parent_zone,
        ip_addresses   = '${module.re-%s.re-public-ips}' % vpc,
        resource_group = rg_map[vpc]
    )

    Output("%s-dns-name" % vpc,
        value = cluster_fqdn)
