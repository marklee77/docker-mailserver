FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        fuzzyocr \
        imagemagick \
        pyzor \
        razor \
        sa-compile \
        spamass-milter \
        spamassassin \
        spamassassin-heatu \
        spamassassin-rules-ja && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN rm -f /etc/spamassassin/local.cf

RUN echo "CRON=1" > /etc/default/spamassassin

ADD setup.sh /etc/my_init.d/10-setup

ADD spamd.sh /etc/service/spamd/run
ADD spamass-milter.sh /etc/service/spamass-milter/run

EXPOSE 783 1234
