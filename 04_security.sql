-- Bokhandel Databas – Säkerhet & Behörigheter (idempotent)
-- Kan köras separat efter 01_schema.sql om man vill köra enbart säkerhet.

use Bokhandel;
go

-- Skapa login på servernivå (byt lösenord i produktion!)
if not exists (select 1 from sys.server_principals where name = 'bokhandel_lasare')
    create login bokhandel_lasare with password = 'BokH4ndel!Las4re';
go

-- Skapa databasanvändare kopplad till login
if not exists (select 1 from sys.database_principals where name = 'bokhandel_lasare')
    create user bokhandel_lasare for login bokhandel_lasare;
go

-- Lägg till i db_datareader – ger select på alla nuvarande och framtida tabeller
if not exists (
    select 1
    from sys.database_role_members rm
    join sys.database_principals r on rm.role_principal_id = r.principal_id
    join sys.database_principals m on rm.member_principal_id = m.principal_id
    where r.name = 'db_datareader' and m.name = 'bokhandel_lasare'
)
    alter role db_datareader add member bokhandel_lasare;
go
