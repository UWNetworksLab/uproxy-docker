#!/bin/sh

# https://github.com/uProxy/uproxy-docker moved to
# https://github.com/uProxy/uproxy. This script
# keeps older uProxy clients working.

# Note that this does *not* pass along any arguments.
# The only downside of this is that older clients will
# not benefit from the -a switch and will have to wait
# slightly longer for their access codes to appear due
# to Node.js being installed.

echo $@

curl https://raw.githubusercontent.com/uProxy/uproxy/master/install-cloud.sh | sh
