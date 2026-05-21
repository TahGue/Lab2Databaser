create database Bokhandel
    collate SQL_Latin1_General_CP1_CI_AS;
go

use Bokhandel;
go

create table Förlag (
    FörlagID    int             identity(1,1) primary key,
    Namn        nvarchar(150)   not null,
    Land        nvarchar(100)   not null,
    Webbplats   nvarchar(255)   null
);
go

create table Kategorier (
    KategoriID  int             identity(1,1) primary key,
    Namn        nvarchar(100)   not null unique,
    Beskrivning nvarchar(500)   null
);
go

create table Författare (
    ID              int             identity(1,1) primary key,
    Förnamn         nvarchar(100)   not null,
    Efternamn       nvarchar(100)   not null,
    Födelsedatum    date            not null,
    Nationalitet    nvarchar(100)   null
);
go

create table Böcker (
    ISBN13          char(13)        not null primary key
        check (ISBN13 not like '%[^0-9]%' and len(ISBN13) = 13),
    Titel           nvarchar(255)   not null,
    Språk           nvarchar(50)    not null,
    Pris            decimal(10,2)   not null check (Pris >= 0),
    Utgivningsdatum date            not null,
    Omslag          nvarchar(20)    not null default 'Häftad'
        check (Omslag in ('Häftad', 'Inbunden', 'E-bok', 'Ljudbok')),
    Sidor           smallint        null check (Sidor > 0),
    FörlagID        int             null references Förlag(FörlagID)
        on update cascade on delete set null,
    KategoriID      int             null references Kategorier(KategoriID)
        on update cascade on delete set null
);
go

create table BokFörfattare (
    ISBN13          char(13)    not null references Böcker(ISBN13)
        on update cascade on delete cascade,
    FörfattareID    int         not null references Författare(ID)
        on update cascade on delete cascade,
    primary key (ISBN13, FörfattareID)
);
go

create table Butiker (
    ButikID     int             identity(1,1) primary key,
    Butiksnamn  nvarchar(150)   not null,
    Gatuadress  nvarchar(200)   not null,
    Postnummer  char(5)         not null check (Postnummer not like '%[^0-9]%'),
    Stad        nvarchar(100)   not null,
    Telefon     nvarchar(20)    null
);
go

create table LagerSaldo (
    ButikID     int         not null references Butiker(ButikID)
        on update cascade on delete cascade,
    ISBN        char(13)    not null references Böcker(ISBN13)
        on update cascade on delete cascade,
    Antal       smallint    not null default 0 check (Antal >= 0),
    primary key (ButikID, ISBN)
);
go

create table Kunder (
    KundID      int             identity(1,1) primary key,
    Förnamn     nvarchar(100)   not null,
    Efternamn   nvarchar(100)   not null,
    Epost       nvarchar(255)   not null unique,
    Telefon     nvarchar(20)    null,
    Gatuadress  nvarchar(200)   null,
    Postnummer  char(5)         null,
    Stad        nvarchar(100)   null,
    Registrerad date            not null default cast(getdate() as date)
);
go

create table Ordrar (
    OrderID     int             identity(1,1) primary key,
    KundID      int             not null references Kunder(KundID)
        on update cascade on delete cascade,
    ButikID     int             not null references Butiker(ButikID)
        on update cascade on delete no action,
    Orderdatum  datetime2       not null default getdate(),
    Status      nvarchar(30)    not null default 'Mottagen'
        check (Status in ('Mottagen', 'Behandlas', 'Skickad', 'Levererad', 'Avbruten')),
    -- TotalBelopp beräknas och sätts av applikationen vid orderläggning
    TotalBelopp decimal(12,2)   null
);
go

create table OrderRader (
    OrderRadID  int             identity(1,1) primary key,
    OrderID     int             not null references Ordrar(OrderID)
        on update cascade on delete cascade,
    ISBN        char(13)        not null references Böcker(ISBN13),
    Antal       smallint        not null check (Antal > 0),
    Enhetspris  decimal(10,2)   not null check (Enhetspris >= 0)
);
go

create table Anställda (
    AnställdID  int             identity(1,1) primary key,
    ButikID     int             not null references Butiker(ButikID)
        on update cascade on delete cascade,
    Förnamn     nvarchar(100)   not null,
    Efternamn   nvarchar(100)   not null,
    Epost       nvarchar(255)   not null unique,
    Telefon     nvarchar(20)    null,
    Roll        nvarchar(50)    not null default 'Säljare'
        check (Roll in ('Butikschef', 'Säljare', 'Lageransvarig', 'Kassör')),
    Anställd    date            not null default cast(getdate() as date)
);
go

create table Recensioner (
    RecensionsID    int             identity(1,1) primary key,
    ISBN13          char(13)        not null references Böcker(ISBN13)
        on update cascade on delete cascade,
    KundID          int             not null references Kunder(KundID)
        on update cascade on delete cascade,
    Betyg           tinyint         not null check (Betyg between 1 and 5),
    Kommentar       nvarchar(1000)  null,
    Datum           datetime2       not null default getdate()
);
go

create index IX_Böcker_Titel       on Böcker(Titel);
create index IX_Kunder_Epost      on Kunder(Epost);
create index IX_Ordrar_KundID     on Ordrar(KundID);
create index IX_Recensioner_ISBN  on Recensioner(ISBN13);
go

create login bokhandel_lasare with password = 'BokH4ndel!Las4re';
go

create user bokhandel_lasare for login bokhandel_lasare;
go

alter role db_datareader add member bokhandel_lasare;
go
