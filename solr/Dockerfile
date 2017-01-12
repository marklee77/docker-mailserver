FROM solr:alpine
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN solr start && \
    solr create -c dovecot -d basic_configs && \
    solr stop

COPY *.xml /opt/solr/server/solr/dovecot/conf/
USER root
RUN chown solr:solr /opt/solr/server/solr/dovecot/conf/*
USER solr
