#!/bin/bash

set -e

PREBUILT=

echo "image make was reached"

function usage () {
  echo "$0 [-p] [-h] browser version"
  echo "  -p: path to uproxy repo"
  echo "  -h, -?: this help message"
  echo
  echo "If -p is not specified then -p must be passed to run_cloud.sh and run_pair.sh."
  exit 1;
}

while getopts p:h? opt; do
  case $opt in
    p) PREBUILT="$OPTARG" ;;
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

cat <<EOF > $TMP_DIR/Dockerfile
FROM resin/rpi-raspbian:latest

RUN apt-get update --fix-missing
RUN apt-get install -y curl supervisor iptables unattended-upgrades

RUN mkdir /test
COPY test /test

EXPOSE 9000
EXPOSE 9999
EOF

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
  cp -R $PREBUILT/build/dev/uproxy/lib/samples/zork-* $TMP_DIR/zork
  cat <<EOF >> $TMP_DIR/Dockerfile
COPY zork /test/zork/
EOF
fi

./gen_browser.sh "$@" >> $TMP_DIR/Dockerfile

docker build -t uproxy/$BROWSER-$VERSION $TMP_DIR
