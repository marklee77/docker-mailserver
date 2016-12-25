#!/bin/bash

: ${postfix_sqlgrey_db_host:=db}
: ${postfix_sqlgrey_db_port:=5432}
: ${postfix_sqlgrey_db_name:=sqlgrey}
: ${postfix_sqlgrey_db_user:=sqlgrey}
: ${postfix_sqlgrey_db_password:=password}

# set secure umask
umask 0227

cat > /etc/sqlgrey/sqlgrey.conf <<EOF
user = sqlgrey
group = sqlgrey
unix = /var/spool/postfix/sqlgrey/sqlgrey.sock
connect_src_throttle = 5
awl_age = 32
group_domain_level = 2
db_type = Pg
db_host = $postfix_sqlgrey_db_host
db_port = $postfix_sqlgrey_db_port
db_name = $postfix_sqlgrey_db_name
db_user = $postfix_sqlgrey_db_user
db_pass = $postfix_sqlgrey_db_password
EOF
chown sqlgrey:sqlgrey /etc/sqlgrey/sqlgrey.conf

cat > /etc/sqlgrey/psql-env.sh <<EOF
export PGHOST="$postfix_sqlgrey_db_host"
export PGPORT="$postfix_sqlgrey_db_port"
export PGNAME="$postfix_sqlgrey_db_password"
export PGUSER="$postfix_sqlgrey_db_user"
export PGPASSWORD="$postfix_sqlgrey_db_password"
EOF

umask 0022

touch /etc/sqlgrey/clients_ip_whitelist.local
touch /etc/sqlgrey/clients_fqdn_whitelist.local
