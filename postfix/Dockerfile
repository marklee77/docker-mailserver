FROM marklee77/supervisor:xenial
LABEL maintainer="Mark Stillwell <mark@stillwell.me>"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        iproute2 \
        ldap-utils \
        postfix \
        postfix-ldap \
        postfix-pcre && \
    rm -rf \
        /etc/aliases* \
        /etc/postfix/* \
        /var/cache/apt/* \
        /var/lib/apt/lists/*

RUN mkdir -m 0755 -p /etc/ssl/postfix && \
    ln -s /data/postfix/ssl/server.crt /etc/ssl/postfix/server.crt && \
    ln -s /data/postfix/ssl/server.key /etc/ssl/postfix/server.key

COPY root/usr/local/sbin/* /usr/local/sbin/
RUN chmod 755 /usr/local/sbin/*

COPY root/etc/my_init.d/10-postfix-setup /etc/my_init.d/
RUN chmod 755 /etc/my_init.d/10-postfix-setup

COPY root/etc/supervisor/conf.d/postfix.conf /etc/supervisor/conf.d/
RUN chmod 644 /etc/supervisor/conf.d/postfix.conf

EXPOSE 25 587
