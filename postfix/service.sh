#!/bin/bash
# FIXME: umask and default group...

: ${mailserver_fqdn:=localhost.localdomain}
: ${mailserver_domain:=localdomain}
: ${mailserver_subdomain_list:=www ftp mail}
: ${mailserver_ssl_cert_file:=/etc/ssl/certs/ssl-cert-snakeoil.pem}
: ${mailserver_ssl_key_file:=/etc/ssl/private/ssl-cert-snakeoil.key}
: ${mailserver_rbl_list:=zen.spamhaus.org psbl.surriel.com dnsbl.sorbs.net}
: ${mailserver_rhsbl_list:=rhsbl.sorbs.net}

echo $mailserver_fqdn > /etc/mailname

cat > /etc/postfix/master.cf <<EOF
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master" or
# on-line: http://www.postfix.org/master.5.html).
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
#smtp      inet  n       -       -       -       -       smtpd
smtp      inet  n       -       -       -       1       postscreen
smtpd     pass  -       -       -       -       -       smtpd
dnsblog   unix  -       -       -       -       0       dnsblog
tlsproxy  unix  -       -       -       -       0       tlsproxy
submission inet n       -       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o tls_preempt_cipherlist=yes
  -o smtpd_tls_eecdh_grade=ultra
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
#  -o smtpd_milters=unix:opendkim/opendkim.sock
pickup    unix  n       -       -       60      1       pickup
cleanup   unix  n       -       -       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       -       1000?   1       tlsmgr
rewrite   unix  -       -       -       -       -       trivial-rewrite
bounce    unix  -       -       -       -       0       bounce
defer     unix  -       -       -       -       0       bounce
trace     unix  -       -       -       -       0       bounce
verify    unix  -       -       -       -       1       verify
flush     unix  n       -       -       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       -       -       -       smtp
relay     unix  -       -       -       -       -       smtp
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
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

cat > /etc/postfix/main.cf <<EOF
# NOTIFICATIONS

biff = no

# INTERNET HOST AND DOMAIN NAMES

${mailserver_relay_host:+relayhost = $mailserver_relay_host}

myhostname = $mailserver_fqdn
mydomain = $mailserver_domain
myorigin = \$mydomain

# RECEIVING MAIL

${mailserver_proxy_interfaces:+proxy_interfaces = $mailserver_proxy_interfaces}

mydestination =
    localhost,
    localhost.localdomain,
    localhost.\$mydomain,
    \$myhostname,
    \$myhostname.localdomain,
    \$myhostname.\$mydomain,
    ${mailserver_subdomain_list:+$(
        for subdomain in $(eval "echo $mailserver_subdomain_list"); do
            echo -ne "${subdomain},\n    "
            echo -ne "${subdomain}.localdomain,\n    "
            echo -ne "${subdomain}.\$mydomain,\n    "
        done)}localdomain,
    \$mydomain

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
local_recipient_maps = proxy:unix:passwd.byname \$alias_maps

mailbox_size_limit = 0

# TRUST AND RELAY CONTROL

mynetworks = 127.0.0.0/8
relay_domains = \$mydestination

# TLS parameters

tls_ssl_options = NO_COMPRESSION
tls_high_cipherlist = ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA

smtp_use_tls = yes
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_tls_cert_file = $mailserver_ssl_cert_file
smtp_tls_key_file = $mailserver_ssl_key_file
smtp_tls_security_level = may
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache

smtpd_use_tls = yes
smtpd_tls_ask_ccert = yes
smtpd_tls_auth_only = yes
smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtpd_tls_cert_file = $mailserver_ssl_cert_file
smtpd_tls_key_file = $mailserver_ssl_key_file
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
smtpd_sasl_path =
    inet:${DOVECOT_PORT_8100_TCP_ADDR}:${DOVECOT_PORT_8100_TCP_PORT}
smtpd_sasl_local_domain = \$myhostname
smtpd_sasl_security_options = noanonymous

# ADDRESS EXTENSIONS (e.g., user+foo)

append_dot_mydomain = no
recipient_delimiter = +

# DELIVERY TO MAILBOX

mailbox_transport =
    lmtp:inet:${DOVECOT_PORT_8025_TCP_ADDR}:${DOVECOT_PORT_8025_TCP_PORT}

# JUNK MAIL CONTROLS

smtpd_banner = \$myhostname ESMTP
smtpd_helo_required = yes
readme_directory = no
in_flow_delay = 1s
disable_vrfy_command = yes
strict_rfc821_envelopes = yes

postscreen_greet_action = enforce
postscreen_dnsbl_action = enforce
postscreen_access_list = permit_mynetworks
${mailserver_rbl_list:+postscreen_dnsbl_sites = ${mailserver_rbl_list// /, }}

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
    ${mailserver_rbl_list:+$(
        for rbl in $(eval "echo $mailserver_rbl_list"); do
            echo -ne "reject_rbl_client $rbl,\n    "
        done)}${mailserver_rhsbl_list:+$(
        for rhsbl in $(eval "echo $mailserver_rhsbl_list"); do
            echo -ne "reject_rhsbl_client $rhsbl,\n    "
        done)}check_policy_service unix:private/policy-spf,
    check_policy_service unix:sqlgrey/sqlgrey.sock,
    permit

milter_default_action = accept
milter_connect_macros = j {daemon_name} v {if_name} _

#smtpd_milters = unix:opendkim/opendkim.sock unix:clamav/clamav.sock
#                unix:dspam/dspam.sock unix:spamass/spamass.sock

#non_smtpd_milters = unix:opendkim/opendkim.sock unix:dspam/dspam.sock

EOF

exec 1>&2

/usr/sbin/postfix check

exec /usr/lib/postfix/master -d
