docker kill node_exporter cadvisor grafana prometheus
docker ps | grep riot- | awk -F" " '{print $1}' | xargs docker kill
docker network rm br0
