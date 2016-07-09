#!/bin/bash

: ${mailserver_ssl_cert_file:=/etc/ssl/certs/ssl-cert-snakeoil.pem}
: ${mailserver_ssl_key_file:=/etc/ssl/private/ssl-cert-snakeoil.key}

SOLR_URL="http://${SOLR_PORT_8983_TCP_ADDR}:${SOLR_PORT_8983_TCP_PORT}/solr/dovecot"
NETWORK=$(ip a s eth0 | sed -nr '/^\s*inet ([^\s]+).*/{s//\1/p;q}')

cat > /etc/cron.daily/dovecot-solr-optimize <<EOF
#!/bin/bash
curl $SOLR_URL/update?optimize=true &>/dev/null
EOF
chmod 755 /etc/cron.daily/dovecot-solr-optimize

cat > /etc/cron.daily/dovecot-expunge <<EOF
#!/bin/bash
doveadm expunge -A mailbox Spam savedbefore 60d
doveadm expunge -A mailbox Trash savedbefore 60d
EOF
chmod 755 /etc/cron.daily/dovecot-expunge

cat > /etc/cron.d/dovecot <<EOF
* * * * * curl $SOLR_URL/update?commit=true &>/dev/null
EOF

cat > /etc/dovecot/dovecot-ldap.conf.ext <<EOF
uri = $LDAP_URL
tls = yes
auth_bind = yes
pass_attrs = uid=user, userPassword=password, \
  homeDirectory=userdb_home, uidNumber=userdb_uid, gidNumber=userdb_gid

# For LDA: needed?
# user_attrs = homeDirectory=userdb_home, uidNumber=userdb_uid, gidNumber=userdb_gid
EOF
chmod 600 /etc/dovecot/dovecot-ldap.conf.ext

cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap pop3 sieve lmtp

ssl = required
# FIXME: verify cipher list
ssl_cipher_list = ALL:!LOW:!SSLv2:ALL:!aNULL:!ADH:!eNULL:!EXP:RC4+RSA:+HIGH:+MEDIUM
ssl_cert = <$mailserver_ssl_cert_file
ssl_key = <$mailserver_ssl_key_file

auth_mechanisms = plain login
auth_username_format = %Ln
disable_plaintext_auth = yes
login_trusted_networks = 127.0.0.0/8 $NETWORK

passdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap.conf.ext
}

userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/vmail/%u
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
  antispam_backend = dspam
  antispam_signature = X-DSPAM-Signature
  antispam_signature_missing = error
  antispam_trash = Trash
  antispam_spam = Spam
  antispam_unsure =
  antispam_allow_append_to_spam = no

  antispam_dspam_binary = /usr/bin/dspamc
  antispam_dspam_args = --user;%u;--source=error
  antispam_dspam_spam = --class=spam
  antispam_dspam_notspam = --class=innocent
  antispam_dspam_result_header = X-DSPAM-Result

  # fts configuration
  fts_autoindex = yes
  fts = solr
  fts_solr = break-imap-search url=$SOLR_URL/

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

exec /usr/sbin/dovecot -F -c /etc/dovecot/dovecot.conf
