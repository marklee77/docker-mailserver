FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        gnarwl \
        opendkim \
        opendkim-tools \
        opendmarc \
        postfix \
        postfix-ldap \
        postfix-pcre \
        postfix-policyd-spf-python \
        sqlgrey && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN rm -rf /etc/dkimkeys/* /etc/opendkim.conf /etc/opendmarc.conf
RUN find /etc/postfix -depth -mindepth 1 -not -name dynamicmaps.cf -exec rm -rf '{}' \;

COPY postfix-setup.sh /etc/my_init.d/00-postfix-setup
COPY postfix-run.sh /etc/service/postfix/run
RUN chmod 755 /etc/my_init.d/00-postfix-setup /etc/service/postfix/run

VOLUME [ "/etc/dkimkeys", "/etc/postfix", "/etc/ssl/postfix", "/var/lib/postfix" ]

EXPOSE 25 587
