#!/bin/bash
export slapd_admin_password=$(pwgen -s1 32)
export dovecot_ldap_password=$(pwgen -s1 32)
export postfix_ldap_password=$(pwgen -s1 32)
export POSTGRES_PASSWORD=$(pwgen -s1 32)
docker-compose up -d
#while ! docker exec dockermailserver_ldap_1 ldapsearch > /dev/null 2>&1; do sleep 1; done
#sleep 10
#docker exec dockermailserver_ldap_1 ldapaddservice dovecot services
#docker exec dockermailserver_ldap_1 \
#    ldappasswd -D cn=admin,dc=localdomain \
#               -y /etc/ldapscripts/ldapscripts.passwd \
#               -s $dovecot_ldap_password \
#               uid=dovecot,ou=services,dc=localdomain
#docker exec dockermailserver_ldap_1 ldapadduser test people
#docker exec dockermailserver_ldap_1 \
#    ldappasswd -D cn=admin,dc=localdomain \
#               -y /etc/ldapscripts/ldapscripts.passwd \
#               -s test \
#               uid=test,ou=people,dc=localdomain
