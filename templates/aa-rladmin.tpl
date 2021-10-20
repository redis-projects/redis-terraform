#!/bin/bash
echo Creating an aa db for clusters $FQDN1 with $BASTION1 and $FQDN2 with $BASTION2 

rladmin tune cluster default_sharded_proxy_policy all-nodes

rladmin  tune cluster default_shards_placement sparse

rladmin  cluster config handle_redirects enabled

/opt/redislabs/bin/crdb-cli crdb create --name databasename \
--memory-size 2gb --port 12000 --shards-count 2 --replication true \
 --instance fqdn=$FQDN1,username=admin@admin.com,password=admin,url=https://$BASTION2:9443,replication_endpoint=$BASTION2 \
 --instance fqdn=$FQDN2,username=admin@admin.com,password=admin,url=https://$BASTION1:9443,replication_endpoint=$BASTION1