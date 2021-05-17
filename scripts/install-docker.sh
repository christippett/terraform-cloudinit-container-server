#!/bin/sh

# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")

# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
      # If available, use LSB to identify distribution
      export DISTRO="$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)"
    else
      # Otherwise, use release info file
      export DISTRO="$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* \
        | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)"
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO="$UNAME"
unset UNAME

# Ubuntu
# https://docs.docker.com/engine/install/ubuntu/

if [ $DISTRO == "Ubuntu" ]; then
  apt update && apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  apt-get update && apt-get install docker-ce docker-ce-cli containerd.io
fi
