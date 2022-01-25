docker run -d --rm --name node_exporter --net br0 -v /:/host:ro,rslave quay.io/prometheus/node-exporter:latest --path.rootfs=/host
