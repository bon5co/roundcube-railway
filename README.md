# roundcube-railway

Roundcube Webmail (1.7.5) wrapped for Railway: Apache bound to the injected `PORT`, SQLite and the session key on one volume (`/var/roundcube/db`), `X-Forwarded-Proto` trusted for Secure cookies, login page asks for the IMAP server unless `ROUNDCUBEMAIL_DEFAULT_HOST` is set. Used by the Railway template in `bon5co/railwaytemplate2` (`roundcube/`).

Optional variables: `ROUNDCUBEMAIL_DEFAULT_HOST`, `ROUNDCUBEMAIL_DEFAULT_PORT` (143), `ROUNDCUBEMAIL_SMTP_SERVER`, `ROUNDCUBEMAIL_SMTP_PORT` (587), `ROUNDCUBEMAIL_DES_KEY` (24 chars; generated and stored on the volume when unset).
