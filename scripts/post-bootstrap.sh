#!/bin/bash

echo $@
echo $1
echo $PGPASSFILE
# dbname=postgres user=postgres host=localhost port=5432
psql "$1" -f /etc/patroni/init.sql | cat

echo $?
exit 0