FROM marklee77/supervisor:xenial
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        curl \
        iproute2 \
        dovecot-core \
        dovecot-imapd \
        dovecot-ldap \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-pop3d \
        dovecot-sieve \
        dovecot-solr \
        pwgen && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY root/var/lib/dovecot/default.sieve /var/lib/dovecot/
RUN chmod 0644 /var/lib/dovecot/default.sieve
RUN sievec /var/lib/dovecot/default.sieve

RUN rm -rf /etc/dovecot/* && mkdir -m 0755 -p /etc/dovecot/conf.d

RUN groupadd -g 1000 vmail
RUN useradd -g 1000 -u 1000 -d /var/lib/vmail -s /bin/false vmail
RUN mkdir -m 0770 -p /var/lib/vmail && chown -R vmail:vmail /var/lib/vmail

COPY root/etc/my_init.d/10-dovecot-setup /etc/my_init.d/
RUN chmod 0755 /etc/my_init.d/10-dovecot-setup

COPY root/etc/supervisor/conf.d/dovecot.conf /etc/supervisor/conf.d
RUN chmod 0644 /etc/supervisor/conf.d/dovecot.conf

VOLUME [ "/etc/dovecot", "/etc/ssl/dovecot", "/var/lib/dovecot", "/var/lib/vmail" ]

EXPOSE 110 143 4190 8025 8100
