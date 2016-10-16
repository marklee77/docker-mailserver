#!/bin/bash

: ${dovecot_enable_ssl:=yes}
: ${dovecot_require_ssl:=yes}
: ${dovecot_ssl_hostname:=localhost}
: ${dovecot_ssl_ca_cert_file:=/etc/ssl/certs/ca-certificates.crt}
: ${dovecot_ssl_cert_file:=/usr/local/share/ca-certificates/dovecot.crt}
: ${dovecot_ssl_key_file:=/etc/ssl/private/dovecot.key}

: ${dovecot_ldap_url:="ldap://ldap"}
: ${dovecot_ldap_basedn:="dc=localdomain"}
: ${dovecot_ldap_password:=password}

: ${dovecot_solr_url:="http://solr:8983/solr/dovecot/"}
: ${dovecot_tika_url:="http://tika:9998/tika/"}

: ${dovecot_docker_network:=$(ip a s eth0 | sed -nr '/^\s*inet ([^\s]+).*/{s//\1/p;q}')}

umask 0022

if [ -f "/etc/dovecot/dovecot.conf" ]; then
  exec /usr/sbin/dovecot -F -c /etc/dovecot/dovecot.conf
fi

if ! grep -q $dovecot_ssl_hostname /etc/hosts; then
    echo "127.0.1.1\t$dovecot_ssl_hostname" >> /etc/hosts
fi

if [ "$dovecot_enable_ssl" = "yes" ] && ! [ -f "$dovecot_ssl_cert_file" ]; then
    openssl req -newkey rsa:2048 -x509 -nodes -days 365 \
        -subj "/CN=$dovecot_ssl_hostname" \
        -out $dovecot_ssl_cert_file -keyout $dovecot_ssl_key_file
fi

# in case user maps a ca cert into /usr/local/share/ca-certificates
update-ca-certificates

cat > /etc/cron.daily/dovecot-solr-optimize <<EOF
#!/bin/bash
curl $dovecot_solr_url/update?optimize=true &>/dev/null
EOF
chmod 755 /etc/cron.daily/dovecot-solr-optimize

cat > /etc/cron.daily/dovecot-expunge <<EOF
#!/bin/bash
doveadm expunge -A mailbox Spam savedbefore 60d
doveadm expunge -A mailbox Trash savedbefore 60d
EOF
chmod 755 /etc/cron.daily/dovecot-expunge

cat > /etc/cron.d/dovecot <<EOF
* * * * * curl $dovecot_solr_url/update?commit=true &>/dev/null
EOF

rm -f /var/lib/dovecot/ssl-parameters.dat

cat > /etc/dovecot/dovecot-ldap.conf.ext <<EOF
uris = $dovecot_ldap_url
ldap_version = 3
#tls = yes
dn = uid=dovecot,ou=services,$dovecot_ldap_basedn
dnpass = $dovecot_ldap_password
auth_bind = yes
auth_bind_userdn = uid=%u,ou=users,$dovecot_ldap_basedn
base = ou=users,$dovecot_ldap_basedn
scope = subtree
deref = never
#pass_attrs = =userdb_uid=1000, =userdb_gid=1000, =userdb_home=/var/vmail/%u
#pass_filter =
user_attrs = =uid=1000, =gid=1000, =home=/var/vmail/%u
#user_filter =
#iterate_attrs =
#iterate_filter =
EOF
chmod 600 /etc/dovecot/dovecot-ldap.conf.ext
ln -s dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-passdb.conf.ext
ln -s dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-userdb.conf.ext

cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap pop3 sieve lmtp

# FIXME
#ssl = required
# FIXME: get these settings right...
ssl_protocols = !SSLv3 !SSLv2
ssl_cipher_list = EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA256:EECDH:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!IDEA:!ECDSA:kEDH:CAMELLIA128-SHA:AES128-SHA
ssl_prefer_server_ciphers = yes
ssl_options = no_compression
ssl_dh_parameters_length = 2048
ssl_cert = <$dovecot_ssl_cert_file
ssl_key = <$dovecot_ssl_key_file

auth_mechanisms = plain login
auth_username_format = %Ln
disable_plaintext_auth = no # FIXME
login_trusted_networks = 127.0.0.0/8 $dovecot_docker_network

passdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-passdb.conf.ext
}

userdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-userdb.conf.ext
}

mail_location = maildir:~/Maildir

namespace inbox {
  inbox = yes
  location =
  prefix =
  mailbox Archive {
    auto = subscribe
    special_use = \Archive
  }
  mailbox Drafts {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox Sent {
    auto = subscribe
    special_use = \Sent
  }
  mailbox Spam {
    auto = create
    special_use = \Junk
  }
  mailbox Trash {
    auto = create
    special_use = \Trash
  }
}

mail_plugins = fts fts_solr mailbox_alias

plugin {

  mailbox_alias_old = Archive
  mailbox_alias_new = Sent

  # antispam configuration
  # FIXME: check docs on this one again...
  antispam_backend = dspam
  antispam_signature = X-DSPAM-Signature
  antispam_signature_missing = error
  antispam_trash = Trash
  antispam_spam = Spam
  antispam_unsure =
  antispam_allow_append_to_spam = no

  # FIXME: obviously this needs to be some kind of wrapper...
  antispam_dspam_binary = /usr/bin/dspamc
  antispam_dspam_args = --user;%u;--source=error
  antispam_dspam_spam = --class=spam
  antispam_dspam_notspam = --class=innocent
  antispam_dspam_result_header = X-DSPAM-Result

  # fts configuration
  fts_autoindex = yes
  fts = solr
  fts_solr = break-imap-search url=$dovecot_solr_url
  fts_tika = $dovecot_tika_url

  # sieve configuration
  sieve = ~/sieve.default
  sieve_dir = ~/sieve.d

}

# authentication
service auth {
  inet_listener {
    port = 8100
  }
}

# local delivery
service lmtp {
  user = vmail
  inet_listener {
    port = 8025
  }
}

protocol imap {
  imap_client_workarounds = delay-newmail
  mail_max_userip_connections = 10
  mail_plugins = antispam fts fts_solr
}

service imap-login {
  inet_listener imaps {
    # disable the imaps service
    port = 0
  }
}

protocol pop3 {
  pop3_client_workarounds = outlook-no-nuls oe-ns-eoh
  mail_max_userip_connections = 10
}

service pop3-login {
  inet_listener pop3s {
    # disable the pop3s service
    port = 0
  }
}

protocol lmtp {
  deliver_log_format = msgid=%m: %$
  mail_plugins = quota sieve
  postmaster_address = postmaster
  quota_full_tempfail = yes
  rejection_reason = Your message to <%t> was automatically rejected:%n%r
}
EOF
