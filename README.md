# docker-mailserver

## Todo

- Dovecot Antispam: Offlineimap and mbsync don't work with the dovecot
  antispam plugin.
- Vacation Autoresponder: The gnarwl in Xenial packages doesn't support tls,
  and slapd doesn't support selectively disabling the requirement for a
  secure connection.
- Local-Only Users: Fusion Directory includes an option to mark a mail user
  as local-only. I haven't yet figured out a good way to implement this.

## Author

- Mark Stillwell <mark@stillwell.me>
