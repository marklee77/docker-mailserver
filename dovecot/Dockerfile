FROM marklee77/supervisor:stretch
LABEL maintainer="Mark Stillwell <mark@stillwell.me>"

RUN mkdir -p /tmp/run && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        curl \
        dovecot-core \
        dovecot-imapd \
        dovecot-ldap \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-pop3d \
        dovecot-sieve \
        dovecot-solr \
        pwgen && \
    rm -rf \
        /etc/ldap/ldap.conf \
        /var/cache/apt/* \
        /var/lib/apt/lists/*

COPY root/var/lib/dovecot/default.sieve /var/lib/dovecot/
RUN chmod 0644 /var/lib/dovecot/default.sieve && \
    sievec /var/lib/dovecot/default.sieve

RUN groupadd -g 1000 vmail && \
    useradd -g 1000 -u 1000 -d /var/lib/vmail -s /bin/false vmail && \
    mkdir -m 0755 -p /etc/ssl/dovecot && \
    ln -s /data/dovecot/ssl/server.crt /etc/ssl/dovecot/server.crt && \
    ln -s /data/dovecot/ssl/server.key /etc/ssl/dovecot/server.key && \
    rm -rf /etc/dovecot/* && \
    ln -s /data/dovecot/config/dovecot/dovecot.conf /etc/dovecot/dovecot.conf && \
    ln -s /data/dovecot/config/dovecot/secrets.conf /etc/dovecot/secrets.conf && \
    ln -s /data/dovecot/config/dovecot/dovecot-ldap.conf.ext \
          /etc/dovecot/dovecot-ldap.conf.ext && \
    ln -s dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-passdb.conf.ext && \
    ln -s dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-userdb.conf.ext && \
    ln -s /data/dovecot/config/ldap/ldap.passwd /etc/ldap/ldap.passwd && \
    ln -s /data/dovecot/config/ldap/ldap.conf /etc/ldap/ldap.conf && \
    ln -s /data/dovecot/vmail /var/lib/vmail

COPY root/etc/cron.d/dovecot /etc/cron.d/
RUN chmod 0644 /etc/cron.d/dovecot
COPY root/etc/cron.daily/dovecot /etc/cron.daily/
RUN chmod 0755 /etc/cron.daily/dovecot

COPY root/etc/my_init.d/10-dovecot-setup /etc/my_init.d/
RUN chmod 0755 /etc/my_init.d/10-dovecot-setup

COPY root/etc/supervisor/conf.d/dovecot.conf /etc/supervisor/conf.d
RUN chmod 0644 /etc/supervisor/conf.d/dovecot.conf

EXPOSE 110 143 4190 8025 8100 9027
