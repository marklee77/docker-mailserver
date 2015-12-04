FROM solr:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /opt/solr/bin/solr start && \
    /opt/solr/bin/solr create -c dovecot -d basic_configs && \
    /opt/solr/bin/solr stop

USER root
ADD solr-schema.xml /opt/solr/server/solr/dovecot/conf/schema.xml
RUN chown solr:solr /opt/solr/server/solr/dovecot/conf/schema.xml
RUN chmod 644 /opt/solr/server/solr/dovecot/conf/schema.xml
USER solr
