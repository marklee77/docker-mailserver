#!/bin/bash
while ! [ -S /var/run/clamav/clamd.ctl ]; do sleep 1; done

exec /usr/sbin/clamav-milter
