#!/bin/bash

generate_cluster() {
    local result=""
    IFS="," read -ra list <<< "$1"
    for item in "${list[@]}"; do
        result+="$item=http://$item:${ETCD_PEER_LISTEN_PORT},"
    done
    echo "${result%,}"
}

array_to_args() {
    local -n arr=$1
    local args=""
    for key in "${!arr[@]}"; do
        args+="--$key=${arr[$key]} "
    done
    echo "$args"
}

if [[ -z "$INITIAL_CLUSTER" ]]; then
    echo "Error: INITIAL_CLUSTER must be set for all etcd nodes"
    exit 1
fi

if [[ -z "$ETCD_SUPERUSER_PASSWORD" ]]; then
    echo "Error: ETCD_SUPERUSER_PASSWORD must be set"
    exit 1
fi

declare -A arguments
arguments["name"]=${HOSTNAME}
arguments["initial-advertise-peer-urls"]="http://${HOSTNAME}:$ETCD_PEER_LISTEN_PORT"
arguments["listen-peer-urls"]="http://0.0.0.0:$ETCD_PEER_LISTEN_PORT"
arguments["listen-client-urls"]="http://0.0.0.0:${ETCD_CLIENT_LISTEN_PORT}"
arguments["advertise-client-urls"]="http://${HOSTNAME}:${ETCD_CLIENT_LISTEN_PORT}"
arguments["heartbeat-interval"]="1000" # 250/1250
arguments["election-timeout"]="5000"
arguments["initial-cluster-state"]="${CLUSTER_STATE:-"new"}"
arguments["initial-cluster-token"]="${ETCD_CLUSTER_TOKEN}"
arguments["data-dir"]="/data/etcd"
arguments["auto-compaction-retention"]=1
arguments["initial-cluster"]=$(generate_cluster "${INITIAL_CLUSTER}")

args=$(array_to_args arguments)

echo "Running etcd with: $args"
(sleep 0.5 && bash /scripts/etcd_auth.sh) &
etcd $args
