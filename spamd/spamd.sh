#!/bin/bash
exec /usr/sbin/spamd -s mail -u debian-spamd -g debian-spamd --ldap-config -x
