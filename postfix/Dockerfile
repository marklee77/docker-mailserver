FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

RUN /bin/bash -c "rm -f /etc/cron.{daily,weekly}/{apt-compat,bsdmainutils,man-db,passwd}"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
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

RUN rm -rf /etc/aliases* /etc/dkimkeys/* /etc/opendkim.conf /etc/opendmarc.conf
RUN cd /etc/postfix && rm -f main.cf master.cf
RUN usermod -aG opendkim,opendmarc,sqlgrey postfix
RUN cd /var/spool/postfix && \
    mkdir -p opendkim opendmarc sqlgrey && \
    chmod 0750 opendkim opendmarc sqlgrey && \
    chown opendkim:opendkim opendkim && \
    chown opendmarc:opendmarc opendmarc && \
    chown sqlgrey:sqlgrey sqlgrey

COPY postfix-setup.sh /etc/my_init.d/00-postfix-setup
COPY postfix-run.sh /etc/service/postfix/run

COPY sqlgrey-setup.sh /etc/my_init.d/10-sqlgrey-setup
COPY sqlgrey-run.sh /etc/service/sqlgrey/run

VOLUME [ "/etc/dkimkeys", "/etc/postfix", "/etc/ssl/postfix", "/var/lib/postfix" ]

EXPOSE 25 587
