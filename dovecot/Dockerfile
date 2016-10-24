FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        dovecot-antispam \
        dovecot-core \
        dovecot-imapd \
        dovecot-ldap \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-mysql \
        dovecot-pop3d \
        dovecot-sieve \
        dovecot-solr \
        spamc && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN groupadd -g 1000 vmail
RUN useradd -g 1000 -u 1000 -d /var/mail -s /bin/false vmail
RUN rm -rf /etc/dovecot/*

COPY dovecot.sh /etc/service/dovecot/run

VOLUME [ "/etc/dovecot", "/etc/ssl", "/usr/local/share/ca-certificates", \
         "/var/lib/dovecot", "/var/log", "/var/vmail" ]

EXPOSE 110 143 4190 8025 8100
