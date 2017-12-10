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

dn: ou=systems,dc=ldap,dc=dit
objectClass: organizationalUnit
ou: systems

dn: ou=servers,ou=systems,dc=ldap,dc=dit
objectClass: organizationalUnit
ou: servers

dn: cn=mail.fakedomain.test,ou=servers,ou=systems,dc=ldap,dc=dit
cn: mail.fakedomain.test
fdMode: unlocked
ipHostNumber: 127.0.0.1
objectClass: fdServer
objectClass: ipHost
objectClass: ieee802Device
objectClass: fdPostfixServer
postfixMyHostname: mail
postfixMyDomain: fakedomain.test
postfixHeaderSizeLimit: 0
postfixMailboxSizeLimit: 0
postfixMessageSizeLimit: 0
postfixMyDestinations: fakedomain.test

dn: uid=test,ou=people,dc=ldap,dc=dit
cn: Testee McTesterton
sn: McTesterton
givenName: Testee
uid: test
userPassword: $(slappasswd -s "password")
mail: test@fakedomain.test
gosaMailAlternateAddress: test2@fakedomain.test
gosaMailDeliveryMode: []
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: gosaMailAccount
EOF
