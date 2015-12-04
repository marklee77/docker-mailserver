FROM tomcat:6-jre7
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
  RUN apt-get update && \
      apt-get -y install solr-tomcat && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ADD solr-schema.xml /etc/solr/conf/schema.xml
RUN chmod 644 /etc/solr/conf/schema.xml
