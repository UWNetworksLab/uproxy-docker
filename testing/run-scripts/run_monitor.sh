# Boot monitoring servers and metrics.

if netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".8000"' >/dev/null; then
  sh ./serve-zork-metrics.sh
fi

if ! docker ps -a | grep prom/prometheus >/dev/null; then
  HOST_IP=`ip -o -4 addr list docker0 | awk '{print $4}' | cut -d/ -f1`
  docker run -d -p 9090:9090 --add-host zork:$HOST_IP -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus -config.file=/etc/prometheus/prometheus.yml -storage.local.path=/prometheus -storage.local.memory-chunks=10000
fi

if netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".9100"' >/dev/null; then
  cd
  curl -LO https://github.com/prometheus/node_exporter/releases/download/0.12.0/node_exporter-0.12.0.linux-amd64.tar.gz
  tar -xvzf node_exporter-0.12.0.linux-amd64.tar.gz
  cd node_exporter-0.12.0.linux-amd64/
  ./node_exporter > /tmp/node-exporter.out &
fi
