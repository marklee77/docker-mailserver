FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        postfix \
        postfix-ldap \
        postfix-mysql \
        postfix-pcre \
        postfix-policyd-spf-python && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ADD service.sh /etc/service/postfix/run

# data volumes
VOLUME [ "/var/log" ]

# interface ports
EXPOSE 25 587
