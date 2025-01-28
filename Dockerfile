FROM docker.io/library/postgres:16-bookworm AS source
FROM debian:bookworm-slim
COPY --from=source / /
# env from postgres
ENV LANG en_US.utf8
ENV PG_MAJOR 16
ENV PATH $PATH:/usr/lib/postgresql/${PG_MAJOR}/bin
ENV PGDATA /var/lib/postgresql/data
ENV SLEEP_ON_EXIT=0
STOPSIGNAL SIGINT

ENV ETCD_ENDPOINT=
ENV ETCDCTL_COMMAND_TIMEOUT=0.2s
#ENV ETCDCTL_WRITE_OUT=table
ENV ETCDCTL_API=3
ENV ETCD_CLUSTER_TOKEN=
ENV INITIAL_CLUSTER=
ENV ETCD_SUPERUSER_PASSWORD=
ENV PATRONI_ETCD3_USERNAME=etcd
ENV PATRONI_ETCD3_PASSWORD=etcd

ENV PATRONI_NAMESPACE=service
ENV PATRONI_SCOPE="pg_cluster"
ENV PGBOUNCER_ENABLE=true
ENV PGBOUNCER_AUTH_USER=pgbouncer
ENV PGBOUNCER_AUTH_PASS=pgbouncer
ENV PGBOUNCER_AUTH_QUERY="SELECT p_user, p_password FROM public.lookup(\$1)"
ENV PGBOUNCER_LISTEN_PORT=6432
ENV PATRONI_SUPERUSER_USERNAME=postgres
ENV PATRONI_SUPERUSER_PASSWORD=postgres
ENV PATRONI_REPLICATION_USERNAME=replicator
ENV PATRONI_REPLICATION_PASSWORD=replicator
ENV PATRONI_REWIND_USERNAME=rewind
ENV PATRONI_REWIND_PASSWORD=rewind
ENV POSTGRES_LISTEN_PORT=5432
ENV PATRONI_LISTEN_PORT=8008
## https://patroni.readthedocs.io/en/latest/ENVIRONMENT.html#rest-api
ENV PATRONI_RESTAPI_USERNAME=patroni
ENV PATRONI_RESTAPI_PASSWORD=patroni

ENV DEBIAN_FRONTEND=noninteractive CONFDVERSION=0.16.0

RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend \
    && apt update; apt install -y nano wget ca-certificates iputils-ping patroni curl gnupg lsb-release etcd-server etcd-client pgbouncer gettext xxd haproxy --no-install-recommends; apt-get purge -y --auto-remove; apt-get clean -y; rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/haproxy \
    && curl -sL "https://github.com/kelseyhightower/confd/releases/download/v$CONFDVERSION/confd-$CONFDVERSION-linux-$(dpkg --print-architecture)" \
        > /usr/local/bin/confd && chmod +x /usr/local/bin/confd;

COPY scripts /scripts
COPY templates/pgbouncer.template.ini /etc/pgbouncer/pgbouncer.template.ini
COPY templates/postgres.template.yml /etc/patroni/postgres.template.yml
COPY templates/init.template.sql /etc/patroni/init.template.sql
COPY confd/ /etc/confd/
RUN chmod +x /scripts/*

ENTRYPOINT ["/scripts/run.sh"]
CMD ["etcd"]