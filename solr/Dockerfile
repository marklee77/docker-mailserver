FROM solr:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN solr start && \
    solr create -c dovecot -d basic_configs && \
    solr stop

COPY solr-schema.xml /opt/solr/server/solr/dovecot/conf/schema.xml
USER root
RUN chown solr:solr /opt/solr/server/solr/dovecot/conf/schema.xml
RUN chmod 644 /opt/solr/server/solr/dovecot/conf/schema.xml
USER solr
