use Bokhandel;
go

if not exists (select 1 from sys.server_principals where name = 'bokhandel_lasare')
    create login bokhandel_lasare with password = 'BokH4ndel!Las4re';
go

if not exists (select 1 from sys.database_principals where name = 'bokhandel_lasare')
    create user bokhandel_lasare for login bokhandel_lasare;
go

if not exists (
    select 1
    from sys.database_role_members rm
    join sys.database_principals r on rm.role_principal_id = r.principal_id
    join sys.database_principals m on rm.member_principal_id = m.principal_id
    where r.name = 'db_datareader' and m.name = 'bokhandel_lasare'
)
    alter role db_datareader add member bokhandel_lasare;
go
