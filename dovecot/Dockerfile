FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

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
RUN useradd -g 1000 -u 1000 -d /var/lib/vmail -s /bin/false vmail
RUN mkdir -m 770 -p /var/lib/vmail && chown vmail:vmail /var/lib/vmail
RUN rm -rf /etc/dovecot/*

COPY dovecot-setup.sh /etc/my_init.d/00-dovecot-setup
COPY dovecot-run.sh /etc/service/dovecot/run
RUN chmod 755 /etc/my_init.d/00-dovecot-setup /etc/service/dovecot/run

VOLUME [ "/etc/dovecot", "/etc/ssl/dovecot", "/var/lib/vmail" ]

EXPOSE 110 143 4190 8025 8100
