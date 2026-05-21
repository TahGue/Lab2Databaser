use Bokhandel;
go

if object_id('TitlarPerFörfattare', 'V') is not null
    drop view TitlarPerFörfattare;
go

create view TitlarPerFörfattare as
with BokVärde as (
    select
        b.ISBN13,
        b.Pris * isnull(sum(ls.Antal), 0)   as Lagervärde
    from
        Böcker b
        left join LagerSaldo ls on b.ISBN13 = ls.ISBN
    group by
        b.ISBN13, b.Pris
)
select
    f.Förnamn + ' ' + f.Efternamn              as 'Namn',
    datediff(year, f.Födelsedatum, getdate())
        - case
            when month(f.Födelsedatum) > month(getdate())
              or (month(f.Födelsedatum) = month(getdate())
                  and day(f.Födelsedatum) > day(getdate()))
            then 1 else 0
          end                                   as 'Ålder',
    count(distinct bf.ISBN13)                  as 'Titlar',
    isnull(sum(bv.Lagervärde), 0)              as 'Lagervärde'
from
    Författare f
    left join BokFörfattare bf  on f.ID      = bf.FörfattareID
    left join BokVärde      bv  on bf.ISBN13 = bv.ISBN13
group by
    f.ID,
    f.Förnamn,
    f.Efternamn,
    f.Födelsedatum;
go

if object_id('KundOrderÖversikt', 'V') is not null
    drop view KundOrderÖversikt;
go

create view KundOrderÖversikt as
select
    k.KundID,
    k.Förnamn + ' ' + k.Efternamn              as 'Kund',
    k.Epost,
    count(distinct o.OrderID)                   as 'AntalOrdrar',
    isnull(sum(r.Antal * r.Enhetspris), 0)      as 'TotaltKöpt',
    max(o.Orderdatum)                           as 'SenastBeställt',
    sum(case
            when o.Status not in ('Levererad', 'Avbruten') then 1
            else 0
        end)                                    as 'AktivaOrdrar'
from
    Kunder k
    left join Ordrar     o on k.KundID  = o.KundID
    left join OrderRader r on o.OrderID = r.OrderID
group by
    k.KundID,
    k.Förnamn,
    k.Efternamn,
    k.Epost;
go

if object_id('FlyttaBok', 'P') is not null
    drop procedure FlyttaBok;
go

create procedure FlyttaBok
    @FrånButikID    int,
    @TillButikID    int,
    @ISBN           char(13),
    @Antal          smallint = 1
as
begin
    set nocount on;
    set xact_abort on;

    declare @NuvarandeAntal smallint;
    declare @Titel          nvarchar(255);
    declare @FrånNamn       nvarchar(150);
    declare @TillNamn       nvarchar(150);

    if @Antal <= 0
    begin
        raiserror('Antal måste vara större än 0.', 16, 1);
        return;
    end

    if @FrånButikID = @TillButikID
    begin
        raiserror('Käll- och målbutik får inte vara samma.', 16, 1);
        return;
    end

    if not exists (select 1 from Butiker where ButikID = @FrånButikID)
    begin
        raiserror('Källbutiken hittades inte.', 16, 1);
        return;
    end

    if not exists (select 1 from Butiker where ButikID = @TillButikID)
    begin
        raiserror('Målbutiken hittades inte.', 16, 1);
        return;
    end

    if not exists (select 1 from Böcker where ISBN13 = @ISBN)
    begin
        raiserror('Boken hittades inte.', 16, 1);
        return;
    end

    begin transaction;

    select @NuvarandeAntal = Antal
    from LagerSaldo with (updlock, rowlock)
    where ButikID = @FrånButikID and ISBN = @ISBN;

    if @NuvarandeAntal is null
    begin
        rollback transaction;
        raiserror('Boken finns inte i källbutiken.', 16, 1);
        return;
    end

    if @NuvarandeAntal < @Antal
    begin
        rollback transaction;
        raiserror('Otillräckligt lagersaldo i källbutiken.', 16, 1);
        return;
    end

    update LagerSaldo
    set    Antal = Antal - @Antal
    where  ButikID = @FrånButikID and ISBN = @ISBN;

    if exists (select 1 from LagerSaldo where ButikID = @TillButikID and ISBN = @ISBN)
        update LagerSaldo
        set    Antal = Antal + @Antal
        where  ButikID = @TillButikID and ISBN = @ISBN;
    else
        insert into LagerSaldo (ButikID, ISBN, Antal)
        values (@TillButikID, @ISBN, @Antal);

    commit transaction;

    select @Titel    = Titel      from Böcker  where ISBN13  = @ISBN;
    select @FrånNamn = Butiksnamn from Butiker where ButikID = @FrånButikID;
    select @TillNamn = Butiksnamn from Butiker where ButikID = @TillButikID;

    print cast(@Antal as nvarchar) + ' exemplar av "' + @Titel +
          '" har flyttats från ' + @FrånNamn + ' till ' + @TillNamn + '.';
end;
go

if object_id('SökBok', 'P') is not null
    drop procedure SökBok;
go

create procedure SökBok
    @Sökterm nvarchar(255) = '%'
as
begin
    set nocount on;

    select
        b.ISBN13,
        b.Titel,
        b.Språk,
        b.Pris,
        b.Utgivningsdatum,
        string_agg(f.Förnamn + ' ' + f.Efternamn, ', ')
            within group (order by f.Efternamn)  as Författare,
        k.Namn                                   as Kategori,
        fo.Namn                                  as Förlag
    from
        Böcker b
        left join BokFörfattare bf  on b.ISBN13       = bf.ISBN13
        left join Författare    f   on bf.FörfattareID = f.ID
        left join Kategorier    k   on b.KategoriID   = k.KategoriID
        left join Förlag        fo  on b.FörlagID     = fo.FörlagID
    where
        b.Titel like '%' + @Sökterm + '%'
    group by
        b.ISBN13, b.Titel, b.Språk, b.Pris,
        b.Utgivningsdatum, k.Namn, fo.Namn
    order by
        b.Titel;
end;
go

if object_id('HämtaLager', 'P') is not null
    drop procedure HämtaLager;
go

create procedure HämtaLager
    @ISBN char(13)
as
begin
    set nocount on;

    select
        bu.Butiksnamn,
        bu.Stad,
        ls.Antal
    from
        LagerSaldo ls
        join Butiker bu on ls.ButikID = bu.ButikID
    where
        ls.ISBN = @ISBN
    order by
        bu.Stad;
end;
go

grant execute on SökBok      to bokhandel_lasare;
grant execute on HämtaLager  to bokhandel_lasare;
grant execute on FlyttaBok   to bokhandel_lasare;
go
