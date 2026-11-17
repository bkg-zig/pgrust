# bkg-core-admin Custom-Image – basiert auf pgrust (PostgreSQL 18.6 in Rust).
#
# pgrust bringt bereits mit: pgvector, pg_cron, pg_stat_statements, pgcrypto,
# uuid-ossp.Dieses Image ergänzt nur, was der Supabase-kompatible Stack braucht:
#   - openssl  -> selbstsigniertes TLS-Zertifikat (EntryPoint)
#   - pgjwt    -> reine SQL-Extension (nicht in pgrust enthalten)
#   - init/*.sql -> Supabase-Rollen und -Schemas
#
# Dies ist eine reine Custom-Änderung (Branch `mango`).Kein Upstream-Code
# wird verändert; Fixes für pgrust selbst gehören in Branch `tango`.

FROM malisper/pgrust:v0.4-beta

USER root

# TLS-Zertifikat braucht openssl; pgrust selbst bringt es nicht mit.
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl \
 && rm -rf /var/lib/apt/lists/*

# pgjwt ist reines SQL und setzt pgcrypto voraus (in pgrust vorhanden).
# Ablage im Share-Verzeichnis, das pgrust für Extension-Dateien nutzt.
COPY pgjwt/pgjwt.control /usr/local/bin/share/extension/pgjwt.control
COPY pgjwt/pgjwt--0.2.0.sql /usr/local/bin/share/extension/pgjwt--0.2.0.sql

# Supabase-kompatible Rollen/Schemas (laufen beim ersten Init genau einmal).
COPY init/ /docker-entrypoint-initdb.d/

# Custom EntryPoint: TLS-Zertifikat + Passwörter der Service-Rollen.
COPY entrypoint.sh /usr/local/bin/entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/entrypoint-wrapper.sh

# pgrust-Konfiguration (TLS, pg_cron, Logging).
COPY postgresql.conf /etc/postgresql/postgresql.conf

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
