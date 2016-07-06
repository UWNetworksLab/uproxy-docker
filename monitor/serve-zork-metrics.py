from prometheus_client import start_http_server, Gauge
import time
import telnetlib

tn = telnetlib.Telnet("zork", "9000")

getters_gauge = Gauge('number_of_getters', 'Number of uProxy instances connected to this cloud instance.')

def update_getters_count():
  try:
    tn.write("getters" + "\n")
  except e:
    print "Write to zork failed"
    return
  zork_output = tn.read_some()
  # Remove new line character from output and cast to int
  num_of_getters = int(zork_output[:len(zork_output)-1])

  getters_gauge.set(num_of_getters)

if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(8000)

    while True:
      # Ping zork every 3 seconds.
      time.sleep(3)
      update_getters_count()

