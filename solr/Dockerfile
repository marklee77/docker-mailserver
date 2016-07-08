FROM solr:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN solr start && \
    solr create -c dovecot -d basic_configs && \
    solr stop

COPY solr-schema.xml /opt/solr/server/solr/dovecot/conf/managed-schema
USER root
RUN chown solr:solr /opt/solr/server/solr/dovecot/conf/managed-schema
RUN chmod 644 /opt/solr/server/solr/dovecot/conf/managed-schema
USER solr
