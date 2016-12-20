#!/bin/bash
: ${postfix_fqdn:=localhost.localdomain}

: ${postfix_ssl_ca_cert_file:=/etc/ssl/certs/ca-certificates.crt}
: ${postfix_ssl_cert_file:=/etc/ssl/postfix/postfix.crt}
: ${postfix_ssl_key_file:=/etc/ssl/postfix/postfix.key}

: ${postfix_ldap_url:=ldap://ldap}
: ${postfix_ldap_tls:=yes}
: ${postfix_ldap_tls_ca_cert_file:=$postfix_ssl_ca_cert_file}
: ${postfix_ldap_tls_require_cert:=yes}
: ${postfix_ldap_basedn:=dc=ldap,dc=dit}
: ${postfix_ldap_password:=password}

: ${postfix_sasl_path:=inet:dovecot:8100}
: ${postfix_mailbox_transport:=lmtp:inet:dovecot:8025}

: ${postfix_rbl_list:=zen.spamhaus.org psbl.surriel.com dnsbl.sorbs.net}
: ${postfix_rhsbl_list:=rhsbl.sorbs.net}
: ${postfix_message_size_limit:=104857600}

docker_network=$(ip a s eth0 | sed -n '/^\s*inet \([^ ]*\).*/{s//\1/p;q}')

# set secure umask
umask 0227

if ! [ -f "$postfix_ssl_cert_file" ]; then
    openssl req -newkey rsa:2048 -x509 -nodes -days 365 \
        -subj "/CN=$(hostname)" \
        -out $postfix_ssl_cert_file -keyout $postfix_ssl_key_file
fi

[ -f "/etc/postfix/master.cf" ] && exit 0

cat > /etc/postfix/ldap-virtual-domains.cf <<EOF
EOF

cat > /etc/postfix/ldap-domains.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
search_base = $postfix_ldap_basedn
scope = one
query_filter = (&(objectClass=domain)(dc=%s))
result_attribute = dc
EOF

cat > /etc/postfix/ldap-accounts.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
search_base = ou=people,$postfix_ldap_basedn
scope = one
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(mail=%s))
result_attribute = mail
EOF

cat > /etc/postfix/ldap-aliases.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
search_base = ou=people,$postfix_ldap_basedn
scope = one
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(gosamailAlternateAddress=%s))
result_attribute = mail
EOF

cat > /etc/postfix/ldap-forward.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
search_base = ou=people,$postfix_ldap_basedn
scope = one
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(|(mail=%s)(gosamailAlternateAddress=%s)))
result_attribute = mail,gosaMailForwardingAddress
EOF

cat > /etc/postfix/ldap-forward-only.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
search_base = ou=people,$postfix_ldap_basedn
scope = one
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(|(mail=%s)(gosamailAlternateAddress=%s)))
result_attribute = gosaMailForwardingAddress
EOF

chown postfix:postfix /etc/postfix/ldap-*

# set normal umask
umask 0022

echo $postfix_fqdn > /etc/mailname

cat > /etc/postfix/master.cf <<EOF
# ==========================================================================
# service  type  private unpriv  chroot  wakeup  maxproc command + args
#                (yes)   (yes)   (no)    (never) (100)
# ==========================================================================
smtp       inet  n       -       y       -       1       postscreen
smtpd      pass  -       -       y       -       -       smtpd
dnsblog    unix  -       -       y       -       0       dnsblog
tlsproxy   unix  -       -       y       -       0       tlsproxy
submission inet  n       -       y       -       -       smtpd
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
pickup     unix  n       -       y       60      1       pickup
cleanup    unix  n       -       y       -       0       cleanup
qmgr       unix  n       -       n       300     1       qmgr
tlsmgr     unix  -       -       y       1000?   1       tlsmgr
rewrite    unix  -       -       y       -       -       trivial-rewrite
bounce     unix  -       -       y       -       0       bounce
defer      unix  -       -       y       -       0       bounce
trace      unix  -       -       y       -       0       bounce
verify     unix  -       -       y       -       1       verify
flush      unix  n       -       y       1000?   0       flush
proxymap   unix  -       -       n       -       -       proxymap
proxywrite unix  -       -       n       -       1       proxymap
smtp       unix  -       -       y       -       -       smtp
relay      unix  -       -       y       -       -       smtp
showq      unix  n       -       y       -       -       showq
error      unix  -       -       y       -       -       error
retry      unix  -       -       y       -       -       error
discard    unix  -       -       y       -       -       discard
local      unix  -       n       n       -       -       local
virtual    unix  -       n       n       -       -       virtual
lmtp       unix  -       -       y       -       -       lmtp
anvil      unix  -       -       y       -       1       anvil
scache     unix  -       -       y       -       1       scache
policy-spf unix  -       n       n       -       0       spawn
  user=nobody argv=/usr/bin/policyd-spf
EOF

cat > /etc/postfix/main.cf <<EOF
# NOTIFICATIONS

biff = no

# INTERNET HOST AND DOMAIN NAMES

myhostname = $postfix_fqdn
myorigin = \$mydomain

# RECEIVING MAIL

mydestination =
virtual_transport = $postfix_mailbox_transport
virtual_mailbox_domains = proxy:ldap:/etc/postfix/ldap-domains.cf
virtual_mailbox_maps = proxy:ldap:/etc/postfix/ldap-accounts.cf
virtual_alias_maps = proxy:ldap:/etc/postfix/ldap-aliases.cf
                     proxy:ldap:/etc/postfix/ldap-forward.cf
                     proxy:ldap:/etc/postfix/ldap-forward-only.cf

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
postscreen_dnsbl_sites = ${postfix_rbl_list// /, }

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
#smtpd_milters = unix:opendkim/opendkim.sock unix:opendmarc/opendmarc.sock
#non_smtpd_milters = unix:opendkim/opendkim.sock
EOF