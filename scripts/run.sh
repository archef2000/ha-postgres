#!/bin/bash

export ETCD_PEER_LISTEN_PORT=${ETCD_PEER_LISTEN_PORT:-2380}
export ETCD_CLIENT_LISTEN_PORT=${ETCD_CLIENT_LISTEN_PORT:-2379}

generate_etcd_hosts() {
    local result=""
    IFS="," read -ra list <<< "$1"
    for item in "${list[@]}"; do
        result+="$item:$ETCD_CLIENT_LISTEN_PORT,"
    done
    echo "${result%,}"
}

global_export() {
    export $1=$2
    sed -i "/^export ${1}/d" ~/.bashrc
    echo "export ${1}=${2}" >> ~/.bashrc
}

global_export PATRONI_ETCD3_HOSTS $(generate_etcd_hosts "${ETCD_ENDPOINT}")

generate_etcdctl_endpoints() {
    local input=$1
    local delimiter=$2
    local result=""
    IFS="$delimiter" read -ra list <<< "$input"
    for item in "${list[@]}"; do
        result+="http://$item:$ETCD_PEER_LISTEN_PORT,"
    done
    result=${result%,}
    echo "$result"
}

global_export ETCDCTL_ENDPOINTS $(generate_etcdctl_endpoints "${ETCD_ENDPOINT}" ",")

if [[ -z "$PATRONI_ETCD3_USERNAME" || -z "$PATRONI_ETCD3_PASSWORD" ]]; then
  echo "Error: PATRONI_ETCD3_USERNAME and PATRONI_ETCD3_PASSWORD must be set"
  exit 1
fi

global_export ETCDCTL_USER $PATRONI_ETCD3_USERNAME:$PATRONI_ETCD3_PASSWORD

if [[ $1 == "proxy" ]]
then
    echo "Proxying requests to primary on port 5432 and read-only requests to port 5433"
    echo "Patroni namespace: '$PATRONI_NAMESPACE' scope: '$PATRONI_SCOPE'"
    /scripts/haproxy.sh
elif [[ $1 == "etcd" ]]
then
    echo "etcd"
    /scripts/etcd.sh
elif [[ $1 == "postgres" ]]
then
    echo "postgres"
    /scripts/patroni.sh
else
    /scripts/scram.sh "$1"
fi
