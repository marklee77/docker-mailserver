#!/bin/bash

: ${mailserver_maildir_name:=Maildir}

cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap pop3 sieve lmtp

ssl = required
ssl_cipher_list = ALL:!LOW:!SSLv2:ALL:!aNULL:!ADH:!eNULL:!EXP:RC4+RSA:+HIGH:+MEDIUM
${mailserver_ssl_cert_file:+ssl_cert = <$mailserver_ssl_cert_file}
${mailserver_ssl_key_file:+ssl_key = <$mailserver_ssl_key_file}

auth_mechanisms = plain login
auth_username_format = %Ln

disable_plaintext_auth = yes

passdb {
  driver = pam
}

userdb {
  driver = passwd
}

mail_location = maildir:~/$mailserver_maildir_name

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
    auto = subscribe
    special_use = \Junk
  }
  mailbox Trash {
    auto = subscribe
    special_use = \Trash
  }
}

plugin {


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
  
  # fts solr configuration
  fts = solr
  fts_solr = url=http://${SOLR_PORT_8983_TCP_ADDR}:${SOLR_PORT_8983_TCP_PORT}/solr/

  # sieve configuration
  sieve = ~/.dovecot.sieve
  sieve_dir = ~/.sieve.d
  
}

# authentication for postfix
service auth {
  unix_listener /var/spool/postfix/private/dovecot-auth {
    user = postfix
    group = postfix
    mode = 0660
  }
}

# local delivery for postfix
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    user = postfix
    group = postfix
    mode = 0600
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

protocol lda {
  deliver_log_format = msgid=%m: %$
  mail_plugins = sieve
  postmaster_address = postmaster
  quota_full_tempfail = yes
  rejection_reason = Your message to <%t> was automatically rejected:%n%r
}

protocol lmtp {
  deliver_log_format = msgid=%m: %$
  mail_plugins = sieve
  postmaster_address = postmaster
  quota_full_tempfail = yes
  rejection_reason = Your message to <%t> was automatically rejected:%n%r
}
EOF

exec /usr/sbin/dovecot -F -c /etc/dovecot/dovecot.conf
