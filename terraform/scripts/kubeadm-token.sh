#!/usr/bin/env bash

# Extract "host" and "usr" argument from the input into HOST shell variable
eval "$(jq -r '@sh "HOST=\(.host) USR=\(.usr)"')"

# Fetch the join command
CMD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    $USR@$HOST sudo kubeadm token create --print-join-command)

# Produce a JSON object containing the join command
jq -n --arg command "$CMD" '{"command":$command}'