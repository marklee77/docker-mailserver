#!/bin/bash

# This is a bit of a hack, but source the functions from the debian init script
# so we can run configure_instance. Stop sourcing at the first line starting
# with case, as this is where the script actually starts executing the
# start/stop/reload/etc tasks.
eval "$(perl -pe 'exit 0 if /^case/' < /etc/init.d/postfix)"
configure_instance

cd /var/spool/postfix
mkdir -p hold trace
chown postfix hold trace

exec /usr/lib/postfix/sbin/master -d
