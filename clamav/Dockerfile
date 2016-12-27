FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        clamav-daemon \
        clamav-freshclam \
        clamav-milter && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY clamd.conf /etc/clamav/clamd.conf
COPY clamav-milter.conf /etc/clamav/clamav-milter.conf
COPY freshclam.conf /etc/clamav/freshclam.conf
RUN chown clamav:clamav /etc/clamav/*.conf && chmod 0644 /etc/clamav/*.conf

COPY setup.sh /etc/my_init.d/10-setup

COPY clamd.sh /etc/service/clamd/run
COPY clamav-milter.sh /etc/service/clamav-milter/run

COPY freshclam.cron /etc/cron.hourly/freshclam
RUN chmod 0755 /etc/cron.hourly/freshclam

VOLUME [ "/var/lib/clamav" ]
