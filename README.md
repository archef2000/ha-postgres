# ha-postgres
## deploy
1. copy the docker-compose file to the desired location
2. edit the volumes path
3. set all environment variables to random secret values
4. run `docker compose up -d`

## motivation
I wanted to have an easy way to deploy a postgres cluster that has the least amount of moving parts and has one of the latest portgres versions with a posibility to upgrade it later.

## constraints
* at least 3 etcd containers
* at lease 2 postgres containers, but 3 are recommended
* at least 1 postgres-proxy container, but 2 are recommended for less downtime between updates

## architecture
```mermaid
flowchart TD

A[App] --> proxy

subgraph proxy[proxy service]
otherProxies[...]
subgraph proxy1
:5432[Listens on port 5432 for the current primary]
:5433[Listens on port 5433 for the replicas]
end
end

:5432 --> postgres1 --> etcd
:5433 --> postgres2 --> etcd
:5433 --> postgres3 --> etcd

proxy1 --> etcd  

subgraph postgres service
postgres1[primary]
subgraph replicas
postgres3["replica of primary (postgres3)"]
postgres2["replica of primary (postgres2)"]
end
end

subgraph etcd[etcd service]
etcd1
etcd2
etcd3
end
```

## Usefull commands
```bash
etcdctl endpoint status --write-out=table
etcdctl member list
patronictl list
# check if postgres1 is the master
curl http://postgres1:8008/master
# test connection to proxy
psql postgres://postgres:postgres@postgresha:5432
```
