#!/bin/bash

# FIXME: where to get ldap info?

fqdn=$(cat </etc/mailname)
docker_network=$(ip a s eth0 | sed -n '/^\s*inet \([^ ]*\).*/{s//\1/p;q}')

[ -f /etc/opendkim.com ] && exit 0

# set secure umask
umask 0227

cat > /etc/opendkim.conf <<EOF
Canonicalization    relaxed/relaxed
ExternalIgnoreList  refile:/etc/opendkim/TrustedHosts
InternalHosts       refile:/etc/opendkim/TrustedHosts
KeyTable            refile:/etc/opendkim/KeyTable
SigningTable        refile:/etc/opendkim/SigningTable
LogWhy              yes
PidFile             /var/run/opendkim/opendkim.pid
Socket              local:/var/spool/postfix/opendkim/opendkim.sock
UMask               0117
SyslogSuccess       yes
UserID              opendkim:opendkim
AutoRestart         yes
Background          yes
DNSTimeout          5
EOF

opendkim-genkey -r -b 2048 -h sha256 -s mail -D /etc/opendkim -d $fqdn

# set normal umask
umask 0022

cd /etc/opendkim
echo -e "127.0.0.0/8\n$docker_network" > TrustedHosts

# FIXME: these need ldap
echo "$fqdn $fqdn:mail:/etc/opendkim/mail.private" > KeyTable
echo "*@$fqdn $fqdn" > SigningTable
