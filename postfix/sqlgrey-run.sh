#!/bin/bash

: ${postfix_sqlgrey_db_host:=db}
: ${postfix_sqlgrey_db_port:=5432}
: ${postfix_sqlgrey_db_name:=sqlgrey}
: ${postfix_sqlgrey_db_user:=sqlgrey}
: ${postfix_sqlgrey_db_password:=password}

export PGHOST="$postfix_sqlgrey_db_host"
export PGPORT="$postfix_sqlgrey_db_port"
export PGNAME="$postfix_sqlgrey_db_password"
export PGUSER="$postfix_sqlgrey_db_user"
export PGPASSWORD="$postfix_sqlgrey_db_password"

# do not start sqlgrey before database is available
while ! psql <<< "\\q" >/dev/null 2>&1; do sleep 1; done

exec /usr/sbin/sqlgrey
