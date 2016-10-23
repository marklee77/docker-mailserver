#!/bin/bash

: ${postfix_fqdn:=localhost.localdomain}
: ${postfix_domain:=localdomain}
: ${postfix_subdomain_list:=www ftp mail}

: ${postfix_ssl_hostname:=$postfix_fqdn}
: ${postfix_ssl_ca_cert_file:=/etc/ssl/certs/ca-certificates.crt}
: ${postfix_ssl_cert_file:=/usr/local/share/ca-certificates/postfix.crt}
: ${postfix_ssl_key_file:=/etc/ssl/private/postfix.key}

: ${postfix_ldap_url:=ldap://ldap}
: ${postfix_ldap_tls:=yes}
: ${postfix_ldap_tls_ca_cert_file:=$postfix_ssl_ca_cert_file}
: ${postfix_ldap_tls_require_cert:=yes}
: ${postfix_ldap_basedn:=dc=localdomain}
: ${postfix_ldap_password:=password}

: ${postfix_sasl_path:=inet:dovecot:8100}
: ${postfix_mailbox_transport:=lmtp:inet:dovecot:8025}

: ${postfix_rbl_list:=zen.spamhaus.org psbl.surriel.com dnsbl.sorbs.net}
: ${postfix_rhsbl_list:=rhsbl.sorbs.net}
: ${postfix_message_size_limit:=104857600}

docker_network=$(ip a s eth0 | sed -n '/^\s*inet \([^ ]*\).*/{s//\1/p;q}')

umask 0022

if [ -f "/etc/postfix/master.cf" ]; then
  exec /usr/lib/postfix/sbin/master -d
fi

if ! [ -f "$postfix_ssl_cert_file" ]; then
    openssl req -newkey rsa:2048 -x509 -nodes -days 365 \
        -subj "/CN=$postfix_ssl_hostname" \
        -out $postfix_ssl_cert_file -keyout $postfix_ssl_key_file
fi

# in case user maps a ca cert into /usr/local/share/ca-certificates
update-ca-certificates

echo $postfix_fqdn > /etc/mailname

cat > /etc/postfix/master.cf <<EOF
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master" or
# on-line: http://www.postfix.org/master.5.html).
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (no)    (never) (100)
# ==========================================================================
smtp      inet  n       -       y       -       1       postscreen
smtpd     pass  -       -       y       -       -       smtpd
dnsblog   unix  -       -       y       -       0       dnsblog
tlsproxy  unix  -       -       y       -       0       tlsproxy
submission inet n       -       y       -       -       smtpd
  -o milter_macro_daemon_name=ORIGINATING
  -o syslog_name=postfix/submission
  -o smtpd_client_restrictions=
  -o smtpd_helo_restrictions=
  -o smtpd_milters=opendkim/opendkim.sock
  -o smtpd_recipient_restrictions=
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sender_restrictions=
  -o smtpd_tls_eecdh_grade=ultra
  -o smtpd_tls_security_level=encrypt
  -o tls_preempt_cipherlist=yes
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d \${recipient}
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a\$sender - \$nexthop!rmail (\$recipient)
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r \$nexthop (\$recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t\$nexthop -f\$sender \$recipient
scalemail-backend unix	-	n	n	-	2	pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store \${nexthop} \${user} \${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  \${nexthop} \${user}
policy-spf unix    -       n       n       -       0     spawn
  user=nobody argv=/usr/bin/policyd-spf
EOF

cat > /etc/postfix/ldap-aliases.cf <<EOF
server_host = $postfix_ldap_url
ldap_version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = uid=postfix,ou=services,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
base = ou=people,$postfix_ldap_basedn
scope = one
dereference = 0
result_attribute = alias
EOF

cat > /etc/postfix/main.cf <<EOF
# NOTIFICATIONS

biff = no

# INTERNET HOST AND DOMAIN NAMES

${postfix_relay_host:+relayhost = $postfix_relay_host}

myhostname = $postfix_fqdn
myorigin = \$mydomain

# RECEIVING MAIL

${postfix_proxy_interfaces:+proxy_interfaces = $postfix_proxy_interfaces}

mydestination =
    localhost,
    localhost.localdomain,
    localhost.\$mydomain,
    \$myhostname,
    \$myhostname.localdomain,
    \$myhostname.\$mydomain,
    ${postfix_subdomain_list:+$(
        for subdomain in $(eval "echo $postfix_subdomain_list"); do
            echo -ne "${subdomain},\n    "
            echo -ne "${subdomain}.\$mydomain,\n    "
        done)}localdomain,
    \$mydomain

alias_maps = ldap:/etc/postfix/ldap-aliases.cf
local_recipient_maps = FIXME

mailbox_size_limit = 0

# TRUST AND RELAY CONTROL

mynetworks = 127.0.0.0/8 $docker_network
relay_domains = \$mydestination

# TLS parameters

tls_high_cipherlist = EECDH+AESGCM:EDH+AESGCM:EECDH+AES256:EDH+AES256
tls_ssl_options = NO_COMPRESSION

smtp_tls_CAfile = $postfix_ssl_ca_cert_file
smtp_tls_cert_file = $postfix_ssl_cert_file
smtp_tls_key_file = $postfix_ssl_key_file
smtp_tls_security_level = may
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache

smtpd_tls_ask_ccert = yes
smtpd_tls_auth_only = yes
smtpd_tls_CAfile = $postfix_ssl_ca_cert_file
smtpd_tls_cert_file = $postfix_ssl_cert_file
smtpd_tls_key_file = $postfix_ssl_key_file
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_mandatory_ciphers = high
smtpd_tls_received_header = yes
smtpd_tls_security_level = may
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtpd_tls_session_cache_timeout = 3600s

# AUTHENTICATION

smtpd_sasl_auth_enable = no
smtpd_sasl_authenticated_header = no
smtpd_sasl_type = dovecot
smtpd_sasl_path = $postfix_sasl_path
smtpd_sasl_local_domain = \$myhostname
smtpd_sasl_security_options = noanonymous

# ADDRESS EXTENSIONS (e.g., user+foo)

append_dot_mydomain = no
recipient_delimiter = +

# DELIVERY TO MAILBOX

mailbox_transport = $postfix_mailbox_transport

# JUNK MAIL CONTROLS

smtpd_banner = \$myhostname ESMTP
smtpd_helo_required = yes
readme_directory = no
in_flow_delay = 1s
disable_vrfy_command = yes
strict_rfc821_envelopes = yes
message_size_limit = $postfix_message_size_limit

postscreen_greet_action = enforce
postscreen_dnsbl_action = enforce
postscreen_access_list = permit_mynetworks
${postfix_rbl_list:+postscreen_dnsbl_sites = ${postfix_rbl_list// /, }}

policy-spf_time_limit = 3600s

smtpd_recipient_restrictions =
    permit_mynetworks,
    reject_unauth_pipelining,
    reject_unknown_client_hostname,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname,
    reject_unknown_helo_hostname,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    reject_non_fqdn_recipient,
    reject_unknown_recipient_domain,
    reject_unlisted_recipient,
    reject_unauth_destination,
    ${postfix_rbl_list:+$(
        for rbl in $(eval "echo $postfix_rbl_list"); do
            echo -ne "reject_rbl_client $rbl,\n    "
        done)}${postfix_rhsbl_list:+$(
        for rhsbl in $(eval "echo $postfix_rhsbl_list"); do
            echo -ne "reject_rhsbl_client $rhsbl,\n    "
        done)}check_policy_service unix:private/policy-spf,
#    check_policy_service unix:sqlgrey/sqlgrey.sock,
    permit

#content_filter = inet:amavis:8025

milter_default_action = accept
smtpd_milters = unix:opendkim/opendkim.sock unix:opendmarc/opendmarc.sock
non_smtpd_milters = unix:opendkim/opendkim.sock
EOF
