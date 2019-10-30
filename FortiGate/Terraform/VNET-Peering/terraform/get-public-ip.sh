#!/bin/bash

ip=$(curl -s https://ifconfig.io)

jq -n --arg ip "$ip" '{"ip":$ip}'