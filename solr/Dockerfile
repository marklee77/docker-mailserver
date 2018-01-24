FROM solr:7-slim
LABEL maintainer="Mark Stillwell <mark@stillwell.me>"

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends curl && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*

RUN mkdir -m 0755 -p /data && \
    chown solr:solr /data && \
    rmdir /opt/solr/server/solr/mycores && \
    ln -s /data /opt/solr/server/solr/mycores
VOLUME ["/data"]

COPY *.xml /opt/solr/server/solr/configsets/_default/conf/
RUN chown solr:solr /opt/solr/server/solr/configsets/_default/conf/*.xml

USER solr

ENTRYPOINT ["docker-entrypoint.sh", "solr-precreate", "dovecot"]

HEALTHCHECK CMD curl -f http://localhost:8983/solr/dovecot/admin/ping
