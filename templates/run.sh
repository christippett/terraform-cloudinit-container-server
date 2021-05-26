#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

compose() {
  /usr/bin/docker run --rm \
    --name "compose-$(date +%s)" \
    --label "traefik.enable=false" \
    -w "${dir}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${dir}:${dir}" \
    docker/compose:latest "$@"
}

usage() {
  echo -e "$(
    cat <<EOF
🐳 ${BLUE}${B}Usage:${X}${WHITE} $(basename "${BASH_SOURCE[0]}") [-h] COMMAND [args...]${X}

${WHITE}${B}Commands:${X}
${ORANGE} start      ${X} docker compose pull/up
${ORANGE} stop       ${X} docker compose rm/stop
${ORANGE} restart    ${X} docker compose restart

${BLUE}
                    ##        .
              ## ## ##       ==
           ## ## ## ##      ===
       /""""""""""""""""\___/ ===
  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
       \______ o          __/
         \    \        __/
          \____\______/
${X}
EOF
  )"
  exit
}

parse_params() {
  if [ -z "$*" ]; then
    usage
  fi

  case "$1" in
  start)
    print_cmd "up"
    msg "🚀 ${WHITE}${B}Starting...${X}"
    compose up
    ;;
  stop)
    print_cmd "rm -fs"
    msg "🧨 ${WHITE}${B}Stopping...${X}"
    compose rm -fs
    ;;
  restart)
    print_cmd "rm -fs" "pull --ignore-pull-failures --include-deps" "up"
    msg "💥 ${WHITE}${B}Restarting...${X}"
    compose rm -fs
    compose pull --ignore-pull-failures --include-deps
    compose up
    ;;
  help)
    usage
    ;;
  *)
    print_cmd "$*"
    compose "$@"
    ;;
  esac
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

msg() {
  echo >&2 -e "${1-}"
}

print_cmd() {
  for cmd in "${@}"; do
    msg "🐳 ${BLUE}docker compose${X} ${WHITE}${cmd}${X}"
  done
  msg "${BLACK}⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺${X}"
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    X='\033[0;0m' B='\033[1m' WHITE='\033[37m' ORANGE='\033[0;33m' BLUE='\033[1;36m' BLACK='\033[1;30m'
  else
    X='' B='' WHITE='' ORANGE='' BLUE='' BLACK=''
  fi
}

setup_colors
parse_params "$@"
