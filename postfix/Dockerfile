FROM marklee77/supervisor:xenial
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
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

COPY root/usr/local/sbin/* /usr/local/sbin/
RUN chmod 755 /usr/local/sbin/*

COPY root/etc/my_init.d/10-postfix-setup /etc/my_init.d/
RUN chmod 755 /etc/my_init.d/10-postfix-setup

COPY root/etc/supervisor/conf.d/postfix.conf /etc/supervisor/conf.d/
RUN chmod 644 /etc/supervisor/conf.d/postfix.conf

VOLUME [ "/etc/dkimkeys" ]

EXPOSE 25 587
