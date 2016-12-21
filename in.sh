#!/bin/bash

# "...must fetch the resource and place it in the given directory"
# "The script must emit the fetched version (metadata optional)"

set -e
exec 3>&1 # make stdout available as fd 3 for the result
exec 1>&2 # redirect all output to stderr for logging

# for jq
PATH=/usr/local/bin:$PATH

default_host=$(ip route | awk '/default/ { print $3 }')
payload=$(mktemp $TMPDIR/resource-in.XXXXXX)

# source, version.ref, params
cat > $payload <&0

approle_id=$(jq -r '.source.approle_id' < $payload)
secret_path=$(jq -r '.source.path' < $payload)
scheme=$(jq -r '.source.scheme // "https"' < $payload)
insecure=$(jq -r '.source.insecure // "false"' < $payload)
vault_port=$(jq -r '.source.port // "8200"' < $payload)
vault_host=$(jq -r '.source.host // ""' < $payload)
if [ "$vault_host" == "" ]; then
    vault_host=$default_host
fi

curl_params=""
if [ "$insecure" != "false" ]; then
    curl_params="-k"
fi

APPROLE_TOKEN=$(curl $curl_params -s -X POST -d "{\"role_id\":\"$approle_id\"}" $scheme://$vault_host:$vault_port/v1/auth/approle/login | jq -r '.auth.client_token')

# destination directory as $1
destination=${1}
cd $destination

curl -s $curl_params -H "X-Vault-Token:$APPROLE_TOKEN" $scheme://$vault_host:$vault_port/v1/${secret_path} > secrets.json

echo "{\"version\":{\"date\":\"$(date +%s)\"}}" >&3
