FROM library/ubuntu:trusty
RUN apt-get -y update && apt-get -y install python python-pip

RUN pip install prometheus_client

COPY serve-zork-metrics.py /
CMD ["python","/serve-zork-metrics.py"]
