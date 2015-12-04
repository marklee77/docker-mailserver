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
        mailutils \
        postfix \
        postfix-ldap \
        postfix-mysql \
        postfix-pcre \
        postfix-policyd-spf-python && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ADD postfix-service.sh /etc/service/postfix/run
ADD dovecot-service.sh /etc/service/dovecot/run

# data volumes
VOLUME [ "/var/log" ]

# interface ports
EXPOSE 25 143 587
