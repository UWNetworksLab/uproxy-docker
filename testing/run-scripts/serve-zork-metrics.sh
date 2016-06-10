docker build -t zork-metrics ../../monitor
HOST_IP=`ip -o -4 addr list docker0 | awk '{print $4}' | cut -d/ -f1`
docker run -d -p 8000:8000 --add-host zork:$HOST_IP zork-metrics


