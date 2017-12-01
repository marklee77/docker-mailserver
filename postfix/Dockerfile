FROM marklee77/supervisor:xenial
LABEL maintainer="Mark Stillwell <mark@stillwell.me>"

RUN mkdir -p /tmp/run && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        iproute2 \
        ldap-utils \
        postfix \
        postfix-ldap \
        postfix-pcre && \
    rm -rf \
        /etc/aliases* \
        /etc/ldap/ldap.conf \
        /etc/mailname \
        /etc/postfix/* \
        /var/cache/apt/* \
        /var/lib/apt/lists/*

RUN mkdir -m 0755 -p /etc/ssl/postfix && \
    ln -s /data/postfix/ssl/server.crt /etc/ssl/postfix/server.crt && \
    ln -s /data/postfix/ssl/server.key /etc/ssl/postfix/server.key && \
    ln -s /data/postfix/config/mailname /etc/mailname && \
    ln -s /data/postfix/config/postfix/master.cf /etc/postfix/master.cf && \
    ln -s /data/postfix/config/postfix/main.cf /etc/postfix/main.cf && \
    ln -s /data/postfix/config/postfix/conf.d /etc/postfix/conf.d && \
    ln -s /data/postfix/config/ldap/ldap.passwd /etc/ldap/ldap.passwd && \
    ln -s /data/postfix/config/ldap/ldap.conf /etc/ldap/ldap.conf

COPY root/etc/my_init.d/10-postfix-setup /etc/my_init.d/
COPY root/usr/local/sbin/postfix-run /usr/local/sbin/
RUN chmod 0755 /etc/my_init.d/10-postfix-setup /usr/local/sbin/postfix-run

COPY root/etc/supervisor/conf.d/postfix.conf /etc/supervisor/conf.d/
RUN chmod 0644 /etc/supervisor/conf.d/postfix.conf

EXPOSE 25 587
