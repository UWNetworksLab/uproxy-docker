#!/bin/bash

#
# setup_browser.sh - Generate commands to download a web browser (by type and version) for a docker image.
#
# Usage:
#   setup_browser.sh type version
#    - Type: 'chrome' or 'firefox'
#    - Version: 'stable' or 'beta' or 'canary'

source "${BASH_SOURCE%/*}/utils.sh" || (echo "cannot find utils.sh" && exit 1)

# $1 is the version
function get_chrome () {
  
  case $1 in
    stable)
      URL=https://dl.dropboxusercontent.com/u/87113035/chromium_browser_45.0.2454.85-0ubuntu0.15.04.1.1181_armhf.deb
      ;;
    beta)
      URL=https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb
      ;;
    canary)
      URL=https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb
      ;;
    *)
      log "Unknown chrome version $1. Options are stable, beta, and canary."
      exit 1
      ;;
  esac
  cat <<EOF
RUN echo BROWSER=chrome >/etc/test.conf
ADD $DRIVERURL /tmp/driver.zip
RUN unzip -qq /tmp/driver.zip -d /usr/bin
RUN wget $URL -O /tmp/chrome.deb
RUN dpkg -i /tmp/chrome.deb || apt-get -f install -y
EOF
}

function get_localchrome () {
  # validate the path.   
  case $1 in
    stable)
      local v=$(chrome_build_path Release)
      ;;
    debug)
      local v=$(chrome_build_path Debug)
      ;;
    *)
      log "Unknown localchrome version $1. Options are stable and debug."
      exit 1
      ;;
  esac
  # localchrome is an additional mount at runtime, into
  # /test/chrome.  Just generate a wrapper script here.
  cat <<EOF
RUN echo BROWSER=chrome >/etc/test.conf
RUN echo '#!/bin/bash' >/usr/bin/google-chrome; echo 'pushd /test/chrome; ./chrome --no-sandbox \$@' >>/usr/bin/google-chrome ; chmod +x /usr/bin/google-chrome
EOF
}

function get_firefox () {
  cat <<EOF
RUN echo BROWSER=firefox >/etc/test.conf

# jpm requires Node.js.
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install npm || apt-get install -f
RUN apt-get install -qq nodejs
RUN apt-get install -qq nodejs-legacy || apt-get install -f
RUN npm install jpm -g

# Firefox dependencies (apt-get install -f handles this for Chrome).
RUN apt-get -qq install libasound2 libdbus-glib-1-2 libgtk2.0.0 libgtk-3-0

EOF

  # From Firefox 48 onwards, jpm only works with *unbranded Firefox builds*.
  # These are available for Firefox stable and beta.
  #
  # At the time of writing (August 2016), there's *very little* documentation
  # online about these builds. Even though add-on signing has been a
  # multi-year project, jpm's documentation barely mentions the unbranded
  # builds - this is the only relevant doc I could find:
  #   https://wiki.mozilla.org/Add-ons/Extension_Signing#Unbranded_Builds
  #
  # From examining the folders linked to in that page it's clear that the
  # unbranded builds are built nightly. However, in the absence of a useful
  # symlink such as "latest", we have to do a bunch of work to find the latest
  # build.
  #
  # Note: We *could* use the regular Firefox builds with the help of jpm sign.
  # However, since that would require us to create, manage, and somehow include
  # in the build API keys for a round-trip to addons.mozilla.org, we instead
  # use the unbranded builds.

  # The builds are stored in one of two directories:
  #   http://archive.mozilla.org/pub/firefox/tinderbox-builds/mozilla-release-linux64-add-on-devel/
  #   http://archive.mozilla.org/pub/firefox/tinderbox-builds/mozilla-beta-linux64-add-on-devel/
  case $1 in
    stable)
  # Inside this directory we'll find a bunch of directories, each containing a
  # nightly build. We want to find the *last*. This will be the *most recent*.
  # In the absence of an FTP server, we use wget to mirror that directory's
  # immediate children so that we can figure out the latest build's directory.
  # Note that this can be slow when there are a lot of nightly builds.
      readonly TMP=$(mktemp -d)
      readonly NIGHTLY_TOP_LEVEL=http://archive.mozilla.org/pub/firefox/tinderbox-builds/mozilla-release-linux64-add-on-devel/
      wget -r -np -l 1 -nH --cut-dirs=4 -P $TMP $NIGHTLY_TOP_LEVEL
      readonly LATEST_NIGHTLY=$(basename $(find $TMP -mindepth 1 -maxdepth 1 -type d|sort|tail -1))
      cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; wget -r -l1 -nd -A '*add-on-devel.tar.bz2' $NIGHTLY_TOP_LEVEL/$LATEST_NIGHTLY/
RUN cd /usr/share ; tar xf /tmp/ff/*add-on-devel.tar.bz2
RUN ln -s /usr/share/firefox/firefox /usr/bin/firefox
EOF
      ;;
    beta)
      readonly TMP=$(mktemp -d)
      readonly NIGHTLY_TOP_LEVEL=http://archive.mozilla.org/pub/firefox/tinderbox-builds/mozilla-beta-linux64-add-on-devel/
      wget -r -np -l 1 -nH --cut-dirs=4 -P $TMP $NIGHTLY_TOP_LEVEL
      readonly LATEST_NIGHTLY=$(basename $(find $TMP -mindepth 1 -maxdepth 1 -type d|sort|tail -1))
      cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; wget -r -l1 -nd -A '*add-on-devel.tar.bz2' $NIGHTLY_TOP_LEVEL/$LATEST_NIGHTLY/
RUN cd /usr/share ; tar xf /tmp/ff/*add-on-devel.tar.bz2
RUN ln -s /usr/share/firefox/firefox /usr/bin/firefox
EOF
      ;;
    arm)
      cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; wget -O firefox.deb 'http://security.debian.org/debian-security/pool/updates/main/f/firefox-esr/firefox-esr_45.3.0esr-1~deb8u1_armhf.deb'
RUN dpkg -i /tmp/ff/firefox.deb || apt-get install -f
EOF
      ;;
    *)
      log "Unknown firefox version $1. Options are stable and beta."
      ;;
  esac
}

function get_node () {
  cat <<EOF
RUN echo BROWSER=node >/etc/test.conf
EOF
  case $1 in
    stable)
      cat <<EOF
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
EOF
            ;;
    *)
      log "Unknown node version $1. Only option right now is stable."
      ;;
  esac
  cat <<EOF
RUN apt-get install -y nodejs
EOF

}

case $1 in
  chrome)
    get_chrome $2
    ;;
  firefox)
    get_firefox $2
    ;;
  localchrome)
    get_localchrome $2 $3
    ;;
  node)
    get_node $2
    ;;
  *)
    log "Unknown browser $1.  Options are chrome, localchrome, firefox, and node."
    exit 1
esac
