FROM marklee77/supervisor:alpine
LABEL mainteiner="Mark Stillwell <mark@stillwell.me>"

RUN apk add --update --no-cache \
        bind-tools \
        opendkim \
        opendkim-utils&& \
    rm -rf \
        /etc/opendkim/* \
        /var/cache/apk/* && \
    mkdir -m 0755 -p /var/lib/opendkim && \
    chown opendkim:opendkim /var/lib/opendkim

COPY root/usr/local/sbin/rotate-dkim-keys /usr/local/sbin/
RUN chmod 0755 /usr/local/sbin/rotate-dkim-keys && \
    ln -s /usr/local/sbin/rotate-dkim-keys /etc/periodic/daily/rotate-dkim-keys

COPY root/etc/opendkim/opendkim.conf /etc/opendkim/
RUN chmod 0644 /etc/opendkim/opendkim.conf

COPY root/etc/my_init.d/10-opendkim-setup /etc/my_init.d/
RUN chmod 0755 /etc/my_init.d/10-opendkim-setup

COPY root/etc/supervisor/conf.d/opendkim.conf /etc/supervisor/conf.d/
RUN chmod 0644 /etc/supervisor/conf.d/opendkim.conf

VOLUME ["/var/lib/opendkim"]

EXPOSE 1025
