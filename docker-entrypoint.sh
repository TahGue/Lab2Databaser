#!/bin/bash
set -e

# Start SQL Server i bakgrunden
/opt/mssql/bin/sqlservr &

echo "Väntar på att SQL Server ska starta..."
for i in {1..30}; do
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -Q "select 1" > /dev/null 2>&1; then
        echo "SQL Server är redo"
        break
    fi
    echo "  ...väntar ($i)"
    sleep 1
done

# Kör init-skript enbart vid första start
if [ ! -f /var/opt/mssql/.init-done ]; then
    echo "Kör 01_schema.sql..."
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -d master -i /init/01_schema.sql
    
    echo "Kör 02_demodata.sql..."
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -d Bokhandel -i /init/02_demodata.sql
    
    echo "Kör 03_views_and_sp.sql..."
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -d Bokhandel -i /init/03_views_and_sp.sql
    
    touch /var/opt/mssql/.init-done
    echo "Databasen Bokhandel är initierad."
else
    echo "Databasen finns redan, hoppar över init-skript."
fi

# Håll sqlservr i förgrunden
wait
