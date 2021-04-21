# Terraform Tool

This tool enables the provisioning of multiple Redis Enterprise clusters across multiple zones using a yaml configuration file

## Running
- Configure ssh
   - add the following to your .ssh/config
    ```Host *
     StrictHostKeyChecking no
     ForwardAgent yes
    ```
   - For macs:
     - ssh-agent
     - ssh-add -K ~/.ssh/id_rsa
   - For linux:
     - eval $(ssh-agent)
     - ssh-add
- Install terraform
- Download a gcp service account credentials file and name it terraform_account.json
- Install python 3.7 and above with pip and virtualenv (optional)
- pip install -r requirements.txt
  - This will install terraformpy to generate the terraform files and pyyaml to parse the configuration file
- name=xxxxx terraformpy, where xxxxx is the name to give this deployment
- terraform init
- terraform plan
- terraform apply
- ssh redislabs@*bastion_ip*
 
## Features Coming soon

- Hybrid cloud support to provision clusters across providers.  Only GCP is currently supported
- Active/Active between zones/cloud providers
- Other services like grafana/ldap etc


```

##
```bash
#find package version
apt-cache policy  ansible
```
