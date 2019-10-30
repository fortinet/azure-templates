#!/bin/bash
# https://medium.com/@jmarhee/using-external-data-sources-with-terraform-c3de27388192

function check_deps() {
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function parse_input() {
  eval "$(jq -r '@sh "export HOST=\(.fgt_public_ipaddress) export USERNAME=\(.fgt_username) export KEY=\(.fgt_ssh_private_key)"')"
  if [[ -z "${HOST}" ]]; then export HOST=none; fi
  if [[ -z "${USERNAME}" ]]; then export USERNAME=none; fi
  if [[ -z "${KEY}" ]]; then export KEY=none; fi
}

function return_token() {
  TOKEN=$(ssh -i $KEY -oStrictHostKeyChecking=no $USERNAME@$HOST "exec api generate-key restapi" | grep "New API key" | sed -e "s/^.*New API key: //")
  echo "$TOKEN" > ../output/token.debug
  jq -n \
    --arg token "$TOKEN" \
    '{"token":$token}'
}

check_deps && \
parse_input && \
sleep 30 && \
return_token