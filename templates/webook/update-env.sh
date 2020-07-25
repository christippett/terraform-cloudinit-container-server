#!/bin/sh

key="$1"
value="$2"

update_env() {
    key="$1"
    value="$2"
    filename="$3"

    sed -i "/^${key}=/s#.*#${key}=${value}#" "$filename"

    # return contents of env file, masking any sensitive values
    printf "[START %s]\n" "$filename"
    sed -E 's/^(.*?(KEY|SECRET).*?)=.*$/\1=**********/' "$filename"
    printf "[END %s]\n\n" "$filename"
}

# replace environment variable
update_env "$key" "$value" /app/.env
update_env "$key" "$value" /app/app.env

printf "Update complete\n"
