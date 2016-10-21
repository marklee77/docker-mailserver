FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        opendkim \
        opendkim-tools \
        opendmarc \
        postfix \
        postfix-ldap \
        postfix-pcre \
        postfix-policyd-spf-python && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN rm /etc/dkimkeys/* -rf /etc/postfix/* /etc/opend{kim,marc}.conf

ADD postfix.sh /etc/service/postfix/run

# data volumes
VOLUME [ "/etc/dkimkeys", "/etc/postfix", "/etc/ssl", "/usr/local/share/ca-certificates", \
         "/var/lib/postfix", "/var/log" ]

# interface ports
EXPOSE 25 587
