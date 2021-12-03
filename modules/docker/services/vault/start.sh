bash stop.sh

cd dockerfiles

docker-compose up -d

#will need dockerfile to get rid of sleep
sleep 2
#docker exec -e URL=https://localhost:8200/ -e CODE=200 -e TIMEOUT=5 vault /bin/sh /content/wait-for-code.sh

root_token=$(docker logs vault 2>&1 | grep "Root Token" | awk -F': ' '{print $2}')

echo "ROOT TOKEN: $root_token"

docker exec vault sh /content/config_vault.sh $root_token 2>&1 > ../start.log