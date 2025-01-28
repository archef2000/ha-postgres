#!/bin/bash
while ! etcdctl member list --write-out=table 2> /dev/null; do
    sleep 0.5
done

LOCK_NAME="/${PATRONI_NAMESPACE}/${PATRONI_SCOPE}/etcd_auth"

if [[ $(ETCDCTL_USER="" etcdctl get tes 2>&1) == *"etcdserver: user name is empty" ]]
then
    echo "etcd already configured with authentication"
    exit 1
fi

current_lock=$(etcdctl get $LOCK_NAME --print-value-only 2>/dev/null)
if [[ ! -z "$current_lock" ]]; then
    echo "Lock already exists. Exiting."
    exit 1
fi
etcdctl put $LOCK_NAME lock-holder-$(hostname) 2>/dev/null
sleep 0.1
current_lock=$(etcdctl get $LOCK_NAME --print-value-only 2>/dev/null)
if [[ "$current_lock" != "lock-holder-$(hostname)" ]]; then
    echo "Lock holder is not the current host. Exiting."
    exit 1
fi

cleanup() {
    etcdctl put $LOCK_NAME failed
}
trap cleanup EXIT

etcdctl role add root 2>/dev/null
etcdctl role grant-permission root --prefix=true readwrite "" 2>/dev/null

etcdctl user add $PATRONI_ETCD3_USERNAME 2>/dev/null <<EOF
$PATRONI_ETCD3_PASSWORD
$PATRONI_ETCD3_PASSWORD
EOF
etcdctl user grant-role $PATRONI_ETCD3_USERNAME root 2>/dev/null

etcdctl user add root  2>/dev/null <<EOF
$ETCD_SUPERUSER_PASSWORD
$ETCD_SUPERUSER_PASSWORD
EOF
etcdctl user grant-role root root 2>/dev/null

etcdctl auth enable 2>/dev/null

trap - EXIT

etcdctl put $LOCK_NAME finished 2>/dev/null
