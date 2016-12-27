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

: ${postfix_message_size_limit:=104857600}
: ${postfix_external_milters:=}

: ${postfix_sqlgrey_db_host:=db}
: ${postfix_sqlgrey_db_port:=5432}
: ${postfix_sqlgrey_db_name:=sqlgrey}
: ${postfix_sqlgrey_db_user:=sqlgrey}
: ${postfix_sqlgrey_db_password:=password}

docker_network=$(ip a s eth0 | sed -n '/^\s*inet \([^ ]*\).*/{s//\1/p;q}')

# set secure umask
umask 0227

if ! [ -f "$postfix_ssl_cert_file" ]; then
    openssl req -newkey rsa:2048 -x509 -nodes -days 365 \
        -subj "/CN=$(hostname)" \
        -out $postfix_ssl_cert_file -keyout $postfix_ssl_key_file
    chmod 0644 $postfix_ssl_cert_file
fi

[ -f "/etc/postfix/master.cf" ] && exit 0

echo -n "$postfix_ldap_password" > /etc/ldap/ldap.passwd

cat > /etc/postfix/ldap-domains.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
scope = one
search_base = $postfix_ldap_basedn
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
scope = one
search_base = ou=people,$postfix_ldap_basedn
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(mail=%s))
result_attribute = mail
EOF

cat > /etc/postfix/ldap-alias-distributions.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
scope = one
search_base = ou=alias,$postfix_ldap_basedn
# postfix does not supply a time string and slapd doesn't support NOW,
# so ignore aliasExpirationdate for the moment.
query_filter = (&(objectClass=mailAliasDistribution)(gosaMailAlternateAddress=%s))
result_attribute = mail
EOF

cat > /etc/postfix/ldap-alias-redirections.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
scope = one
search_base = ou=alias,$postfix_ldap_basedn
# postfix does not supply a time string and slapd doesn't support NOW,
# so ignore aliasExpirationdate for the moment.
query_filter = (&(objectClass=mailAliasRedirection)(mail=%s))
result_attribute = gosaMailForwardingAddress
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
scope = one
search_base = ou=people,$postfix_ldap_basedn
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(|(mail=%s)(gosaMailAlternateAddress=%s)))
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
scope = one
search_base = ou=people,$postfix_ldap_basedn
query_filter = (&(objectClass=gosaMailAccount)(gosaMailDeliveryMode=[*I*])(|(mail=%s)(gosaMailAlternateAddress=%s)))
result_attribute = gosaMailForwardingAddress
EOF

cat > /etc/postfix/ldap-alternates.cf <<EOF
server_host = $postfix_ldap_url
version = 3
start_tls = $postfix_ldap_tls
tls_ca_cert_file = $postfix_ldap_tls_ca_cert_file
tls_require_cert = $postfix_ldap_tls_require_cert
bind = yes
bind_dn = cn=postfix,ou=dsa,$postfix_ldap_basedn
bind_pw = $postfix_ldap_password
scope = one
search_base = ou=people,$postfix_ldap_basedn
query_filter = (&(objectClass=gosaMailAccount)(!(gosaMailDeliveryMode=[*I*]))(gosaMailAlternateAddress=%s))
result_attribute = mail
EOF

chown postfix /etc/postfix/ldap-*

cat > /etc/sqlgrey/sqlgrey.conf <<EOF
user = sqlgrey
group = sqlgrey
unix = /var/spool/postfix/sqlgrey/sqlgrey.sock
connect_src_throttle = 5
awl_age = 32
group_domain_level = 2
db_type = Pg
db_host = $postfix_sqlgrey_db_host
db_port = $postfix_sqlgrey_db_port
db_name = $postfix_sqlgrey_db_name
db_user = $postfix_sqlgrey_db_user
db_pass = $postfix_sqlgrey_db_password
EOF
chown sqlgrey:sqlgrey /etc/sqlgrey/sqlgrey.conf

cat > /etc/sqlgrey/psql-env.sh <<EOF
export PGHOST="$postfix_sqlgrey_db_host"
export PGPORT="$postfix_sqlgrey_db_port"
export PGNAME="$postfix_sqlgrey_db_password"
export PGUSER="$postfix_sqlgrey_db_user"
export PGPASSWORD="$postfix_sqlgrey_db_password"
EOF

dkim_selector="${postfix_fqdn%%.*}$(date +%Y%m%d)"

opendkim-genkey -r -b 2048 -h sha256 -s $dkim_selector -D /etc/dkimkeys -d $postfix_fqdn

cat > /etc/opendkim.conf <<EOF
LDAPBindUser     cn=postfix,ou=dsa,$postfix_ldap_basedn
LDAPBindPassword $postfix_ldap_password
LDAPUseTLS       $([ "$postfix_ldap_tls" = "yes" ] && echo True || echo False)
Canonicalization relaxed/relaxed
InternalHosts    127.0.0.0/8, $docker_network
Selector         $dkim_selector
Domain           $postfix_ldap_url/$postfix_ldap_basedn?ou?one?(&(objectClass=domain)(ou=\$d))
KeyFile          /etc/dkimkeys/${dkim_selector}.private
PidFile          /var/run/opendkim/opendkim.pid
UserID           opendkim:opendkim
UMask            0117
Socket           local:/var/spool/postfix/opendkim/opendkim.sock
Syslog           yes
SyslogSuccess    yes
EOF

# set normal umask
umask 0022

echo $postfix_fqdn > /etc/mailname

cat > /etc/ldap/ldap.conf <<EOF
URI $postfix_ldap_url
BINDDN cn=postfix,ou=dsa,$postfix_ldap_basedn
BASE $postfix_ldap_basedn
TLS_CACERT $postfix_ldap_tls_ca_cert_file
EOF

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
# COMPATIBILITY

compatibility_level = 2

# NOTIFICATIONS

biff = no

# INTERNET HOST AND DOMAIN NAMES

myhostname = $postfix_fqdn
myorigin = \$mydomain

# RECEIVING MAIL

mydestination =

alias_database =
alias_maps =

virtual_transport = lmtp:inet:dovecot:8025
virtual_mailbox_domains = proxy:ldap:/etc/postfix/ldap-domains.cf
virtual_mailbox_maps = proxy:ldap:/etc/postfix/ldap-accounts.cf
virtual_alias_maps = proxy:ldap:/etc/postfix/ldap-alias-distributions.cf,
                     proxy:ldap:/etc/postfix/ldap-alias-redirections.cf,
                     proxy:ldap:/etc/postfix/ldap-forward.cf,
                     proxy:ldap:/etc/postfix/ldap-forward-only.cf,
                     proxy:ldap:/etc/postfix/ldap-alternates.cf

# TRUST AND RELAY CONTROL

mynetworks = 127.0.0.0/8 $docker_network
relay_domains =

# TLS parameters

tls_high_cipherlist = EECDH+AESGCM:EDH+AESGCM:EECDH+AES256:EDH+AES256
tls_ssl_options = NO_COMPRESSION

smtp_tls_block_early_mail_reply = yes
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
smtpd_sasl_local_domain = \$myhostname
smtpd_sasl_path = inet:dovecot:8100
smtpd_sasl_security_options = noanonymous

# ADDRESS EXTENSIONS (e.g., user+foo)

append_dot_mydomain = no
recipient_delimiter = +

# JUNK MAIL CONTROLS

disable_vrfy_command = yes
message_size_limit = $postfix_message_size_limit
smtpd_banner = \$myhostname ESMTP
smtpd_helo_required = yes
strict_rfc821_envelopes = yes

postscreen_access_list = permit_mynetworks
postscreen_greet_action = enforce

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
    check_policy_service unix:private/policy-spf,
    check_policy_service unix:sqlgrey/sqlgrey.sock,
    permit

milter_default_action = accept
smtpd_milters = unix:opendkim/opendkim.sock,
                unix:opendmarc/opendmarc.sock,
                $postfix_external_milters
non_smtpd_milters = unix:opendkim/opendkim.sock
EOF

touch /etc/sqlgrey/clients_ip_whitelist.local
touch /etc/sqlgrey/clients_fqdn_whitelist.local

cat > /etc/opendmarc.conf <<EOF
PidFile          /var/run/opendmarc/opendmarc.pid
UserID           opendmarc:opendmarc
UMask            0117
Socket           local:/var/spool/postfix/opendmarc/opendmarc.sock
Syslog           yes
EOF