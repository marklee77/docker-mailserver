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
        postfix-pcre \
        postfix-policyd-spf-python && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ADD service/postfix.sh /etc/service/postfix/run
ADD service/dovecot.sh /etc/service/dovecot/run

# data volumes
VOLUME [ "/var/log" ]

# interface ports
EXPOSE 25 143 587
