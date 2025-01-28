#!/bin/bash

chown postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

proxy_port=5432

if [[ ${PGBOUNCER_ENABLE,,} == "true" ]]
then
    echo "PgBouncer enabled"
    echo "\"${PGBOUNCER_AUTH_USER}\" \"${PGBOUNCER_AUTH_PASS}\"" >> /etc/pgbouncer/userlist.txt
    envsubst < /etc/pgbouncer/pgbouncer.template.ini > /etc/pgbouncer/pgbouncer.ini
    proxy_port=6432
    pgbouncer /etc/pgbouncer/pgbouncer.ini -u postgres &
fi

export proxy_port
envsubst < /etc/patroni/init.template.sql > /etc/patroni/init.sql
envsubst < /etc/patroni/postgres.template.yml > /etc/patroni/postgres.yml
env

(sleep 5 && echo \n && patronictl list) &
runuser -u postgres -- patroni /etc/patroni/postgres.yml
