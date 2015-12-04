FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        dovecot-antispam \
        dovecot-core \
        dovecot-imapd \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-pop3d \
        dovecot-sieve \
        solr-tomcat && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# data volumes
VOLUME [ "/home", "/tmp", "/var/log", ]

# interface ports
# EXPOSE 25 587
