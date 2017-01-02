#!/bin/bash

# set secure umask
umask 0227

cd /var/lib/spamassassin
[ -f .pyzor/servers ] || setuser debian-spamd pyzor discover
[ -d .razor ] || setuser debian-spamd razor-admin -create
[ -f .razor/identity ] || setuser debian-spamd razor-admin -register
[ -d sa-update-keys ] || setuser debian-spamd sa-update --gpghomedir ./sa-update-keys

[ -f /etc/spamassassin/local.cf ] || cat > /etc/spamassassin/local.cf <<EOF
# report_safe 1
# trusted_networks 212.17.35.
lock_method flock
required_score 5.0

use_bayes 1
bayes_auto_learn 1
bayes_ignore_header X-Bogosity
bayes_ignore_header X-Spam-Flag
bayes_ignore_header X-Spam-Status

normalize_charset 1
EOF
chown debian-spamd:debian-spamd /etc/spamassassin/local.cf
