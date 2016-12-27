FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        ldap-utils \
        opendkim \
        opendkim-tools \
        opendmarc \
        postfix \
        postfix-ldap \
        postfix-pcre \
        postfix-policyd-spf-python \
        postgresql-client \
        sqlgrey && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN rm -rf /etc/aliases* /etc/dkimkeys/* /etc/opendmarc.conf
RUN cd /etc/postfix && rm -f main.cf master.cf
RUN usermod -aG opendkim,opendmarc,sqlgrey postfix
RUN cd /var/spool/postfix && \
    mkdir -p opendkim opendmarc sqlgrey && \
    chmod 0750 opendkim opendmarc sqlgrey && \
    chown opendkim:opendkim opendkim && \
    chown opendmarc:opendmarc opendmarc && \
    chown sqlgrey:sqlgrey sqlgrey

COPY setup.sh /etc/my_init.d/00-setup

COPY postfix.sh /etc/service/postfix/run
COPY sqlgrey.sh /etc/service/sqlgrey/run
COPY opendkim.sh /etc/service/opendkim/run
COPY opendmarc.sh /etc/service/opendmarc/run

VOLUME [ "/etc/dkimkeys" ]

EXPOSE 25 587
