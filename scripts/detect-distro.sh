#!/bin/sh

# Identify OS
# Credit: @terdon
# https://askubuntu.com/a/459425

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
