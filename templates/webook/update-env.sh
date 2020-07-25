#!/bin/sh

key="$1"
value="$2"
filename=/app/.env

# replace environment variable
sed -i "/^${key}=/s#.*#${key}=${value}#" "$filename"

# return contents of env file, masking any sensitive values
printf "[START %s]\n" "$filename"
sed -E 's/^(.*?(KEY|SECRET).*?)=.*$/\1=**********/' "$filename"
printf "\n[END %s]\n\n" "$filename"

printf "Update complete\n"
