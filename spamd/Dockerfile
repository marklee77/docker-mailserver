FROM marklee77/supervisor:xenial
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

COPY root/usr/local/sbin/spamd.sh /usr/local/sbin/
RUN chmod 755 /usr/local/sbin/spamd.sh

COPY root/etc/my_init.d/10-spamd-setup /etc/my_init.d/
RUN chmod 755 /etc/my_init.d/10-spamd-setup

COPY root/etc/supervisor/conf.d/spamd.conf /etc/supervisor/conf.d/
RUN chmod 644 /etc/supervisor/conf.d/spamd.conf

EXPOSE 783 1234
