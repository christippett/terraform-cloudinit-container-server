#!/bin/sh

key="$1"
value="$2"

# replace environment variable
sed -i "/^${key}=/s#.*#${key}=${value}#" /app/.env

# return contents of .env, masking any sensitive values
sed -E 's/^(.*?(KEY|SECRET).*?)=.*$/\1=**********/' /app/.env
