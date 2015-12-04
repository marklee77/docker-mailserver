#!/bin/bash

: ${mailserver_fqdn:=$(hostname -f)}
: ${mailserver_domain:=$(hostname -d)}
: ${mailserver_subdomain_list:=www ftp mail}

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
  -o smtpd_milters=unix:opendkim/opendkim.sock
#smtps     inet  n       -       -       -       -       smtpd
#  -o syslog_name=postfix/smtps
#  -o smtpd_tls_wrappermode=yes
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=\$mua_client_restrictions
#  -o smtpd_helo_restrictions=\$mua_helo_restrictions
#  -o smtpd_sender_restrictions=\$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       -       -       -       qmqpd
pickup    unix  n       -       -       60      1       pickup
cleanup   unix  n       -       -       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
#qmgr     unix  n       -       n       300     1       oqmgr
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
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about \${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d \${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing "lmtp" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd="lmtpd -a" listen="localhost:lmtp" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  user=cyrus argv=/cyrus/bin/deliver -e -r \${sender} -m \${extension} \${user}
#
# ====================================================================
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/cyrus/bin/deliver -e -m \${extension} \${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a\$sender - \$nexthop!rmail (\$recipient)
#
# Other external delivery methods.
#
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r \$nexthop (\$recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t\$nexthop -f\$sender \$recipient
scalemail-backend unix	-	n	n	-	2	pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store \${nexthop} \${user} \${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  \${nexthop} \${user}

# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
policy-spf unix    -       n       n       -       0     spawn
      user=nobody argv=/usr/bin/policyd-spf
EOF

cat > /etc/postfix/main.cf <<EOF
# NOTIFICATIONS

biff = no

# INTERNET HOST AND DOMAIN NAMES

${mailserver_relay_host:+relayhost = $mailserver_relay_host}

${mailserver_fqdn:+myhostname = $mailserver_fqdn}
${mailserver_domain:+mydomain = $mailserver_domain}
myorigin = \$mydomain

# RECEIVING MAIL

${mailserver_proxy_interfaces:+proxy_interfaces = $mailserver_proxy_interfaces}

mydestination = 
    localhost,
    localhost.localdomain,
    localhost.\$mydomain, 
    \$myhostname,
    \$myhostname.localdomain,
    \$myhostname.\$mydomain, ${mailserver_subdomain_list:+$(
        for subdomain in $(eval "echo $mailserver_subdomain_list"); do 
            echo -e "    ${subdomain},\n    ${subdomain}.localdomain,\n    ${subdomain}.\$mydomain,"
        done)}
    localdomain,
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
${mailserver_ssl_cert_file:+smtp_tls_cert_file = $mailserver_ssl_cert_file}
${mailserver_ssl_key_file:+smtp_tls_key_file = $mailserver_ssl_key_file}
smtp_tls_security_level = may
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache

smtpd_use_tls = yes
smtpd_tls_ask_ccert = yes
smtpd_tls_auth_only = yes
smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
${mailserver_ssl_cert_file:+smtpd_tls_cert_file = $mailserver_ssl_cert_file}
${mailserver_ssl_key_file:+smtpd_tls_key_file = $mailserver_ssl_key_file}
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
smtpd_sasl_path = private/dovecot-auth
smtpd_sasl_local_domain = \$myhostname
smtpd_sasl_security_options = noanonymous

# ADDRESS EXTENSIONS (e.g., user+foo)

append_dot_mydomain = no
recipient_delimiter = +

# DELIVERY TO MAILBOX

mailbox_transport = lmtp:unix:private/dovecot-lmtp

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
#postscreen_dnsbl_sites = {{ mailserver_rbl_list|join(', ') }}

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
    #{% for rbl in mailserver_rbl_list -%}
    #reject_rbl_client {{ rbl }},
    #{% endfor -%}
    #{% for rhsbl in mailserver_rhsbl_list -%}
    #reject_rhsbl_client {{ rhsbl }},
    #reject_rhsbl_sender {{ rhsbl }},
    #{% endfor -%}
    check_policy_service unix:private/policy-spf,
    check_policy_service unix:sqlgrey/sqlgrey.sock,
    permit

milter_default_action = accept
milter_connect_macros = j {daemon_name} v {if_name} _

smtpd_milters = unix:opendkim/opendkim.sock unix:clamav/clamav.sock 
                unix:dspam/dspam.sock unix:spamass/spamass.sock

non_smtpd_milters = unix:opendkim/opendkim.sock unix:dspam/dspam.sock

local_destination_concurrency_limit = 5
EOF

exec 1>&2

daemon_directory=/usr/lib/postfix \
command_directory=/usr/sbin \
config_directory=/etc/postfix \
queue_directory=/var/spool/postfix \
mail_owner=postfix \
setgid_group=postdrop \
    /etc/postfix/postfix-script check || exit 1
 
exec /usr/lib/postfix/master
