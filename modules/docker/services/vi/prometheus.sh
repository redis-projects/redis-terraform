envsubst < prometheus/prometheus.yml.template > prometheus/prometheus.yml

docker run -d --rm --name prometheus -p 9090:9090 --net br0 -v $PWD/prometheus/:/etc/prometheus/ prom/prometheus --config.file=/etc/prometheus/prometheus.yml
