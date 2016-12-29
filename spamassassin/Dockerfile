FROM phusion/baseimage:latest
MAINTAINER Mark Stillwell <mark@stillwell.me>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        amavisd-new \
        arj \
        bzip2 \
        cabextract \
        clamav-daemon \
        clamav-freshclam \
        cpio \
        file \
        fuzzyocr \
        gzip \
        lhasa \
        nomarch \
        pax \
        pyzor \
        razor \
        sa-compile \
        spamassassin \
        spamassassin-heatu \
        unrar-free \
        unzip \
        zip \
        zoo && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#ADD postfix.sh /etc/service/postfix/run

# data volumes
#VOLUME [ "/etc/dkimkeys", "/etc/postfix", "/etc/ssl", "/usr/local/share/ca-certificates", \
#         "/var/lib/postfix", "/var/log" ]

# interface ports
#EXPOSE 25 587
