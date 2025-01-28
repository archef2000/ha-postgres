#!/bin/bash

generate_nodes() {
    local result=""
    IFS="," read -ra list <<< "$1"
    for item in "${list[@]}"; do
        result+="-node $item "
    done
    echo "$result"
}

confd "-prefix=$PATRONI_NAMESPACE/$PATRONI_SCOPE" -interval=60 -backend etcdv3 $(generate_nodes $PATRONI_ETCD3_HOSTS) -watch -username $PATRONI_ETCD3_USERNAME -password $PATRONI_ETCD3_PASSWORD -basic-auth
