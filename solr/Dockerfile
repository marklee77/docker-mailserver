FROM solr:7
LABEL maintainer="Mark Stillwell <mark@stillwell.me>"

USER root

RUN mkdir -m 0755 -p /data && \
    chown solr:solr /data && \
    rmdir /opt/solr/server/solr/mycores && \
    ln -s /data /opt/solr/server/solr/mycores
VOLUME ["/data"]

COPY *.xml /opt/solr/server/solr/configsets/_default/conf/
RUN chown solr:solr /opt/solr/server/solr/configsets/_default/conf/*.xml

USER solr

ENTRYPOINT ["docker-entrypoint.sh", "solr-precreate", "dovecot"]
