#!/bin/sh
mkdir -p ssl
cd ssl
mkdir -p csrs certs private newcerts
touch index.txt
echo 1000 >serial
openssl req -config ../openssl.conf -newkey rsa:4096 -x509 -nodes -days 365 \
    -subj "/CN=ca" -sha256 -extensions v3_ca \
    -out certs/ca.cert.pem -keyout private/ca.key.pem

for S in ldap dovecot replica; do
    openssl req -config ../openssl.conf -newkey rsa:4096 -nodes -days 365 \
        -subj "/CN=${S}" -out "csrs/${S}.csr.pem" -keyout "private/${S}.key.pem"
    openssl ca -config ../openssl.conf -batch -md sha256 -days 365 \
        -extensions server_cert \
        -in "csrs/${S}.csr.pem" -out "certs/${S}.cert.pem"
done
