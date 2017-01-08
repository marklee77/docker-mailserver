#!/bin/bash

: ${dovecot_ssl:=required}
: ${dovecot_ssl_dh_parameters_length:=4096}
: ${dovecot_ssl_cert_file:=/etc/ssl/dovecot/dovecot.crt}
: ${dovecot_ssl_key_file:=/etc/ssl/dovecot/dovecot.key}

: ${dovecot_ldap_url:=ldap://ldap}
: ${dovecot_ldap_tls:=yes}
: ${dovecot_ldap_tls_ca_cert_file:=/etc/ssl/certs/ca-certificates.crt}
: ${dovecot_ldap_tls_require_cert:=hard}
: ${dovecot_ldap_basedn:=dc=ldap,dc=dit}
: ${dovecot_ldap_password:=password}

: ${dovecot_solr_url:=http://solr:8983/solr/dovecot}
: ${dovecot_tika_url:=http://tika:9998/tika}

docker_network=$(ip a s eth0 | sed -n '/^\s*inet \([^ ]*\).*/{s//\1/p;q}')

# set secure umask
umask 0227

if ! [ -f "$dovecot_ssl_cert_file" ]; then
    openssl req -newkey rsa:2048 -x509 -nodes -days 365 \
        -subj "/CN=$(hostname)" \
        -out $dovecot_ssl_cert_file -keyout $dovecot_ssl_key_file
fi

[ -f "/etc/dovecot/dovecot.conf" ] && exit 0

cat > /etc/dovecot/dovecot-ldap.conf.ext <<EOF
uris = $dovecot_ldap_url
ldap_version = 3
tls = $dovecot_ldap_tls
tls_ca_cert_file = $dovecot_ldap_tls_ca_cert_file
tls_require_cert = $dovecot_ldap_tls_require_cert
dn = cn=dovecot,ou=dsa,$dovecot_ldap_basedn
dnpass = $dovecot_ldap_password
auth_bind = yes
auth_bind_userdn = uid=%u,ou=people,$dovecot_ldap_basedn
base = ou=people,$dovecot_ldap_basedn
scope = onelevel
deref = never
user_attrs = uid=user,gosaMailQuota=quota_rule=*:storage=%{ldap:gosaMailQuota}M
user_filter = (&(objectClass=gosaMailAccount)(|(uid=%u)(mail=%u)))
iterate_attrs = uid=user
iterate_filter = (objectClass=gosaMailAccount)
EOF
ln -s dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-passdb.conf.ext
ln -s dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-userdb.conf.ext

# set normal umask
umask 0022

cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap pop3 sieve lmtp

ssl = $dovecot_ssl
ssl_protocols = !SSLv2 !SSLv3
ssl_cipher_list = EECDH+AESGCM:EDH+AESGCM:EECDH+AES256:EDH+AES256
ssl_prefer_server_ciphers = yes
ssl_options = no_compression
ssl_dh_parameters_length = $dovecot_ssl_dh_parameters_length
ssl_cert = <$dovecot_ssl_cert_file
ssl_key = <$dovecot_ssl_key_file

auth_mechanisms = plain login
auth_username_format = %Lu
disable_plaintext_auth = yes
login_trusted_networks = 127.0.0.0/8 $docker_network

passdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-passdb.conf.ext
}

userdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-userdb.conf.ext
}

mail_uid = vmail
mail_gid = vmail
mail_home = /var/lib/vmail/%u
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

  # fts configuration
  fts_autoindex = yes
  fts = solr
  fts_solr = break-imap-search url=$dovecot_solr_url/
  fts_tika = $dovecot_tika_url/

  # sieve configuration
  sieve = file:~/sieve.d;active=~/dovecot.sieve
  sieve_max_script_size = 1M
  sieve_max_actions = 256
  sieve_default = /var/lib/dovecot/default.sieve
  sieve_default_name = default

}

# authentication
service auth {
  inet_listener {
    port = 8100
  }

  unix_listener auth-userdb {
    group = vmail
  }
}

# local delivery
service lmtp {
  user = vmail
  inet_listener lmtp {
    port = 8025
  }
}

protocol imap {
  imap_client_workarounds = delay-newmail
  mail_max_userip_connections = 10
  mail_plugins = fts fts_solr
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

cat > /etc/cron.daily/dovecot-solr-optimize <<EOF
#!/bin/bash
curl "$dovecot_solr_url/update?optimize=true" &>/dev/null
EOF
chmod 755 /etc/cron.daily/dovecot-solr-optimize

cat > /etc/cron.daily/dovecot-expunge <<EOF
#!/bin/bash
doveadm expunge -A mailbox Spam savedbefore 60d
doveadm expunge -A mailbox Trash savedbefore 60d
EOF
chmod 755 /etc/cron.daily/dovecot-expunge

cat > /etc/cron.d/dovecot <<EOF
* * * * * dovecot curl "$dovecot_solr_url/update?commit=true" &>/dev/null
EOF
