#!/bin/sh
: ${postfix_ldap_basedn:=dc=ldap,dc=dit}

# do not start opendkim before ldap is available
while ! ldapsearch -Z -D cn=postfix,ou=dsa,$postfix_ldap_basedn -y /etc/ldap/ldap.passwd >/dev/null 2>&1; do sleep 1; done

exec /usr/sbin/opendkim -f
