FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# Install sqlcmd (mssql-tools18) för att kunna köra init-skript
RUN apt-get update \
    && apt-get install -y curl gnupg \
    && curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 \
    && rm -rf /var/lib/apt/lists/*

# Kopiera entrypoint och SQL-skript
COPY docker-entrypoint.sh /usr/local/bin/
COPY 01_schema.sql 02_demodata.sql 03_views_and_sp.sql /init/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER mssql

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
