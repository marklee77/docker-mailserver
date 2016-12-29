#!/bin/bash
exec /usr/sbin/spamd -u debian-spamd -g debian-spamd --ldap-config -x
