FROM library/ubuntu:trusty
RUN apt-get -y update && apt-get -y install python python-pip

RUN pip install prometheus_client

COPY serve_zork_metrics.py /
CMD ["python","/serve_zork_metrics.py"]
