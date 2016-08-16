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
    arm)
    cat <<EOF
RUN apt-get install wget
RUN echo BROWSER=chrome >/etc/test.conf
RUN wget https://dl.dropboxusercontent.com/u/87113035/chromium-browser-l10n_45.0.2454.85-0ubuntu0.15.04.1.1181_all.deb 
RUN wget https://dl.dropboxusercontent.com/u/87113035/chromium-browser_45.0.2454.85-0ubuntu0.15.04.1.1181_armhf.deb 
RUN wget https://dl.dropboxusercontent.com/u/87113035/chromium-codecs-ffmpeg-extra_45.0.2454.85-0ubuntu0.15.04.1.1181_armhf.deb 
RUN dpkg -i chromium-codecs-ffmpeg-extra_45.0.2454.85-0ubuntu0.15.04.1.1181_armf.deb || apt-get -f install
RUN dpkg -i chromium-browser-l10n_45.0.2454.85=0ubuntu0.15.04.1.1181_all.deb chromium-browser_45.0.2454.85-0ubuntu0.15.04.1.1181_armf.deb || apt-get -f install
EOF
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
RUN apt-get install -y nodejs
RUN apt-get install -y wget
RUN apt-get install -y lbzip2
RUN npm install -g jpm

# Firefox dependencies (apt-get install -f handles this for Chrome).
RUN apt-get -qq install libasound2 libdbus-glib-1-2 libgtk2.0.0 libgtk-3-0
EOF
  case $1 in
    stable)
      cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; wget -O firefox-stable.tar.bz2 'https://download.mozilla.org/?product=firefox-latest&os=linux64'
RUN cd /usr/share ; ls /tmp/ff/*.bz2|sort|tail -1|xargs tar xf
RUN ln -s /usr/share/firefox/firefox /usr/bin/firefox
EOF
            ;;
    arm)
      cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; apt-get install firefox-esr
EOF
            ;;

        beta)
            cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; wget -O firefox-beta.tar.bz2 'https://download.mozilla.org/?product=firefox-beta-latest&os=linux64'
RUN cd /usr/share ; ls /tmp/ff/*.bz2|sort|tail -1|xargs tar xf
RUN ln -s /usr/share/firefox/firefox /usr/bin/firefox
EOF
      ;;
    canary)
      cat <<EOF
RUN cd /tmp ; mkdir ff ; cd ff ; wget -r -l1 -nd -A '*linux-x86_64.tar.bz2' https://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-mozilla-aurora/
RUN cd /usr/share ; ls /tmp/ff/*.bz2|sort|tail -1|xargs tar xf
RUN ln -s /usr/share/firefox/firefox /usr/bin/firefox
EOF
      ;;
    *)
      log "Unknown firefox version $1. Options are stable, beta, and canary."
      ;;
  esac
  cat <<EOF
  # Sometimes there are >1 versions in the folder, e.g. following a release.
RUN cd /usr/share ; ls /tmp/ff/*.bz2|sort|tail -1|xargs tar xf
RUN ln -s /usr/share/firefox/firefox /usr/bin/firefox
EOF

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
