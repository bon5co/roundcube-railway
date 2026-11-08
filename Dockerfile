# Roundcube Webmail for Railway.
# Upstream pinned by digest (roundcube/roundcubemail 1.7.5-apache). The wrapper binds Apache to Railway's
# injected PORT (the healthcheck dials it), trusts X-Forwarded-Proto so session cookies get the Secure flag,
# keeps the SQLite database and the session-encryption key on the one volume, and leaves the login page's
# server field open so no deployer variable is needed to reach any IMAP/SMTP host.
FROM roundcube/roundcubemail@sha256:e440257796672b039072bfb09c678984141559f8ff0ddff804bf21e7261d2b65

ENV ROUNDCUBEMAIL_DB_TYPE=sqlite \
    ROUNDCUBEMAIL_DB_DIR=/var/roundcube/db \
    ROUNDCUBEMAIL_SKIN=elastic \
    ROUNDCUBEMAIL_PLUGINS=archive,zipdownload

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["apache2-foreground"]
