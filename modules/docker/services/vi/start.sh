docker build -t riot -f dockerfiles/riot.dockerfile .

bash create_network.sh

bash grafana.sh

bash prometheus.sh

bash cadvisor.sh

bash node_exporter.sh
