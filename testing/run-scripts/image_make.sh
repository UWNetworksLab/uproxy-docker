#!/bin/bash

set -e

PREBUILT=
ARM=false

function usage () {
  echo "$0 [-p] [-h] browser version"
  echo "  -p: path to uproxy repo"
  echo "  -h, -?: this help message"
  echo "  -a: ARM architecture"
  echo
  echo "If -p is not specified then -p must be passed to run_cloud.sh and run_pair.sh."
  exit 1;
}

while getopts p:h:a? opt; do
  case $opt in
    p) PREBUILT="$OPTARG" ;;
    a) ARM=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt 2 ]
then
  usage
fi

BROWSER=$1
VERSION=$2

TMP_DIR=`mktemp -d`

echo "building image in $TMP_DIR"


cp -R ${BASH_SOURCE%/*}/../integration/test $TMP_DIR/test

if $ARM
then
  cat <<EOF > $TMP_DIR/Dockerfile
FROM resin/rpi-raspbian:latest

RUN apt-get -qq update
RUN apt-get -qq install wget unzip bzip2 supervisor iptables unattended-upgrades

RUN mkdir /test
COPY test /test

EXPOSE 9000
EXPOSE 9999
EOF
else
  cat <<EOF > $TMP_DIR/Dockerfile
FROM phusion/baseimage:0.9.19

RUN apt-get -qq update
RUN apt-get -qq install wget unzip bzip2 supervisor iptables unattended-upgrades

RUN mkdir /test
COPY test /test

EXPOSE 9000
EXPOSE 9999
EOF
fi

# Chrome and Firefox need X.
if [ "$BROWSER" = "chrome" ] || [ "$BROWSER" = "firefox" ]
then
  cat <<EOF >> $TMP_DIR/Dockerfile
RUN apt-get install -y xvfb fvwm x11vnc
EXPOSE 5900
EOF
fi

if [ -n "$PREBUILT" ]
then
  mkdir $TMP_DIR/zork
  cp -R $PREBUILT/build/src/lib/samples/zork-* $TMP_DIR/zork
  cat <<EOF >> $TMP_DIR/Dockerfile
COPY zork /test/zork/
EOF
fi

./gen_browser.sh "$@" >> $TMP_DIR/Dockerfile

docker build -t elewis97/$BROWSER-$VERSION $TMP_DIR
