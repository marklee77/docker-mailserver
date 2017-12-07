#!/bin/sh

echo "create ldap entries for testing..."
echo

ldapadd -D cn=admin,dc=ldap,dc=dit -y /etc/ldap/ldap.passwd <<EOF
dn: dc=fakedomain.test,dc=ldap,dc=dit
objectClass: domain
objectClass: top
objectClass: gosaDepartment
dc: fakedomain.test
description: fake domain for testing
ou: fakedomain.test

dn: ou=dsa,dc=ldap,dc=dit
objectClass: organizationalUnit
ou: dsa

dn: cn=dovecot,ou=dsa,dc=ldap,dc=dit
cn: dovecot
userPassword: $(slappasswd -s "password")
objectClass: organizationalRole
objectClass: top
objectClass: simpleSecurityObject

dn: cn=postfix,ou=dsa,dc=ldap,dc=dit
cn: postfix
userPassword: $(slappasswd -s "password")
objectClass: organizationalRole
objectClass: top
objectClass: simpleSecurityObject
EOF
