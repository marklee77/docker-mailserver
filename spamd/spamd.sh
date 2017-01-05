#!/bin/bash

: ${spamd_max_children:=5}

exec /usr/sbin/spamd -s mail -u debian-spamd -g debian-spamd -x -H /var/lib/spamassassin -m $spamd_max_children
