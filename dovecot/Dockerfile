FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        dovecot-core \
        dovecot-imapd \
        dovecot-ldap \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-pop3d \
        dovecot-sieve \
        dovecot-solr && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY default.sieve /var/lib/dovecot/default.sieve
RUN chmod 0644 /var/lib/dovecot/default.sieve
RUN sievec /var/lib/dovecot/default.sieve

RUN rm -rf /etc/dovecot/*

RUN groupadd -g 1000 vmail
RUN useradd -g 1000 -u 1000 -d /var/lib/vmail -s /bin/false vmail
RUN mkdir -m 0770 -p /var/lib/vmail && chown -R vmail:vmail /var/lib/vmail


COPY dovecot-setup.sh /etc/my_init.d/00-dovecot-setup
COPY dovecot-run.sh /etc/service/dovecot/run
RUN chmod 0755 /etc/my_init.d/00-dovecot-setup /etc/service/dovecot/run

VOLUME [ "/etc/dovecot", "/etc/ssl/dovecot", "/var/lib/dovecot", "/var/lib/vmail" ]

EXPOSE 110 143 4190 8025 8100
