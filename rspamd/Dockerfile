FROM marklee77/supervisor:alpine
LABEL maintainer="Mark Stillwell <mark@stillwell.me>"

RUN apk add --update --no-cache \
        rspamd \
        rspamd-client \
        rspamd-controller \
        rspamd-fuzzy \
        rspamd-proxy \
        rspamd-utils && \
    rm -rf /var/cache/apk/*

COPY root/etc/my_init.d/10-rspamd-setup /etc/my_init.d/
RUN chmod 0755 /etc/my_init.d/10-rspamd-setup

COPY root/etc/supervisor/conf.d/rspamd.conf /etc/supervisor/conf.d
RUN chmod 0644 /etc/supervisor/conf.d/rspamd.conf

VOLUME ["/var/lib/rspamd"]

EXPOSE 80 1025 11333 11335
