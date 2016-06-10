from prometheus_client import start_http_server, Gauge
import time
import telnetlib

tn = telnetlib.Telnet("zork", "9000")

connections_gauge = Gauge('number_of_connections', 'Number of uProxy instances connected to this cloud instance.')

def update_connections_count():
  try:
    tn.write("connections" + "\n")
  except e:
    print "Write to zork failed"
    return
  zork_output = tn.read_some()
  # Remove new line character from output and cast to int
  num_of_connections = int(zork_output[:len(zork_output)-1])

  connections_gauge.set(num_of_connections)

if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(8000)
    
    while True:
      # Ping zork every 3 seconds.
      time.sleep(3)
      update_connections_count()

