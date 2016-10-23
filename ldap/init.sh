ldapadd <<EOF
dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectClass: top
olcModuleLoad: memberof.la
olcModulePath: /usr/lib/ldap

dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcMemberOf
objectClass: top
olcOverlay: memberof

dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectClass: top
olcModuleLoad: refint.la
olcModulePath: /usr/lib/ldap

dn: olcOverlay=refint,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: refint
olcRefintAttribute: memberof member manager owner

dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectClass: top
olcModuleLoad: unique.la
olcModulePath: /usr/lib/ldap

dn: olcOverlay=unique,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcUniqueConfig
objectClass: top
olcOverlay: unique
olcUniqueURI: ldap:///?uid,uidNumber,mail?sub
EOF

ldapadd -D cn=admin,$slapd_basedn -y /etc/ldap/ldap.passwd <<EOF
dn: $slapd_basedn
objectClass: dcObject
objectClass: organization
o: $slapd_organization

dn: ou=groups,$slapd_basedn
objectClass: organizationalUnit
ou: groups

dn: ou=people,$slapd_basedn
objectClass: organizationalUnit
ou: people

dn: ou=services,$slapd_basedn
objectClass: organizationalUnit
ou: services

dn: ou=machines,$slapd_basedn
objectClass: organizationalUnit
ou: machines
EOF
