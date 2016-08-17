## BUILDING
##   (from project root directory)
##   $ docker build -t uproxy-uproxy-docker .
##
## RUNNING
##   $ docker run -p 3000:3000 uproxy-uproxy-docker
##
## CONNECTING
##   Lookup the IP of your active docker host using:
##     $ docker-machine ip $(docker-machine active)
##   Connect to the container at DOCKER_IP:3000
##     replacing DOCKER_IP for the IP of your active docker host

FROM gcr.io/stacksmith-images/ubuntu-buildpack:14.04-r8

MAINTAINER Bitnami <containers@bitnami.com>

ENV STACKSMITH_STACK_ID="rajdsz8" \
    STACKSMITH_STACK_NAME="uProxy/uproxy-docker" \
    STACKSMITH_STACK_PRIVATE="1"

RUN bitnami-pkg install node-4.5.0-0 --checksum af047acbfe0c0f918536de0dfa690178808d2e5fc07dfa7acc34c77f0a60fd55

ENV PATH=/opt/bitnami/node/bin:/opt/bitnami/python/bin:$PATH \
    NODE_PATH=/opt/bitnami/node/lib/node_modules

## STACKSMITH-END: Modifications below this line will be unchanged when regenerating

# Node base template
COPY . /app
WORKDIR /app

RUN npm install

CMD ["node"]
