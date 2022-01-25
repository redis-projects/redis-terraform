docker run -d --rm --name grafana -p 3000:3000 grafana/grafana-enterprise

docker exec grafana grafana-cli plugins install redis-explorer-app

docker kill grafana

docker run -d --rm --net br0 --name grafana -p 3000:3000 grafana/grafana-enterprise
