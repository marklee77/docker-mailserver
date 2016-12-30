#!/bin/bash
cd /var/lib/spamassassin
[ -f .pyzor/servers ] || setuser debian-spamd pyzor discover
[ -d .razor ] || setuser debian-spamd razor-admin -create
[ -f .razor/identity ] || setuser debian-spamd razor-admin -register
[ -d sa-update-keys ] || setuser debian-spamd sa-update --gpghomedir ./sa-update-keys
