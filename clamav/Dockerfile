FROM marklee77/supervisor:xenial
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        clamav-daemon \
        clamav-freshclam \
        clamav-milter && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY root/etc/clamav/*.conf /etc/clamav/
RUN chown clamav:clamav /etc/clamav/*.conf && chmod 0644 /etc/clamav/*.conf

COPY root/etc/my_init.d/10-clamav-setup /etc/my_init.d/
RUN chmod 755 /etc/my_init.d/10-clamav-setup

COPY root/etc/supervisor/conf.d/clamav.conf /etc/supervisor/conf.d/
RUN chmod 644 /etc/supervisor/conf.d/clamav.conf

VOLUME [ "/var/lib/clamav" ]

EXPOSE 1234
