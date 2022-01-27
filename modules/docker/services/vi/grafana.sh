sudo chmod -R 777 grafana/

docker run -d --rm --net br0 --name grafana -p 3000:3000 -v $PWD/grafana/:/var/lib/grafana grafana/grafana-enterprise
