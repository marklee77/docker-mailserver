#!/bin/bash
exec setuser spamass-milter /usr/sbin/spamass-milter -p inet:1234 -m
