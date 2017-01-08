#!/bin/bash
source /etc/sqlgrey/psql-env.sh

# do not start sqlgrey before database is available
while ! psql <<< "\\q" >/dev/null 2>&1; do sleep 1; done

exec /usr/sbin/sqlgrey
