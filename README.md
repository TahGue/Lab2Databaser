# Bokhandel – Databasprojekt

Multistore bookstore database for ITHS SQL Server assignment (G/VG).

## Projektöversikt

| Komponent | Beskrivning |
|-----------|-------------|
| **12 tabeller** | 11 entiteter + 1 junction (many-many) |
| **3 stored procedures** | `SökBok`, `HämtaLager`, `FlyttaBok` |
| **2 vyer** | `TitlarPerFörfattare`, `KundOrderÖversikt` |
| **Säkerhet** | SQL-injection skydd på DB-nivå via SP + parameterbinding |
| **Python-app** | SQLAlchemy-klient som enbart anropar SP |
| **Demo data** | 4 butiker, 8 författare, 12 böcker, 6 kunder, 10 recensioner |

## Snabbstart med Docker (rekommenderat)

```bash
# Starta databasen
docker compose up --build

# Vänta på "Databasen Bokhandel är initierad."
# Kör Python-appen (kräver venv + pip install -r requirements.txt)
python bokhandel_app.py
```

## Körskript manuellt (utan Docker)

```sql
-- 1. Skapa databas, tabeller, nycklar, index, säkerhet
01_schema.sql

-- 2. Fyll med demodata
02_demodata.sql

-- 3. Skapa vyer och stored procedures
03_views_and_sp.sql

-- 4. (Valfritt) Kör enbart säkerhet – idempotent
04_security.sql
```

## Python-applikation

```bash
# Skapa virtuell miljö
python -m venv venv
source venv/bin/activate  # macOS/Linux
# eller: venv\Scripts\activate  # Windows

pip install -r requirements.txt
python bokhandel_app.py
```

Appen demonstrerar DB-nivå SQL-injection skydd vid uppstart.

### Beroenden

```
sqlalchemy>=2.0.0
pyodbc>=4.0.0
python-dotenv>=1.0
```

Installera med: `pip install -r requirements.txt`

### Konfiguration (.env)

Lösenord och anslutningsinställningar läses från miljövariabler eller en `.env`-fil (som ignoreras av git):

```bash
# Kopiera mallen och fyll i dina värden
cp .env.example .env
```

**`.env`-fil exempel:**
```bash
DB_SERVER=localhost,1433
DB_NAME=Bokhandel
DB_USER=bokhandel_lasare
DB_PASSWORD=BokH4ndel!Las4re
```

- Om `.env` saknas → appen frågar efter lösenord via `getpass()` (lärarens mönster)
- `.env` ingår **aldrig** i git – se `.gitignore`

## ER-diagram

Se `ER_diagram.md` för komplett Mermaid-diagram med alla tabeller, nycklar och relationer.

## Databasschema

### Entitetstabeller (11 st)

| Tabell | Primärnyckel | Beskrivning |
|--------|--------------|-------------|
| **Förlag** | FörlagID (IDENTITY) | Bokförlag med land och webbplats |
| **Kategorier** | KategoriID (IDENTITY) | Bokgenrer (Skönlitteratur, Thriller, etc) |
| **Författare** | ID (IDENTITY) | Persondata inkl. födelsedatum och nationalitet |
| **Böcker** | ISBN13 (CHAR(13)) | Bokinformation med FK till Förlag/Kategorier |
| **Butiker** | ButikID (IDENTITY) | Butiker med adressuppgifter |
| **Kunder** | KundID (IDENTITY) | Kundregister med kontaktinfo |
| **Ordrar** | OrderID (IDENTITY) | Orderheader med status och datum |
| **OrderRader** | OrderRadID (IDENTITY) | Orderrader: bok, antal, pris |
| **Anställda** | AnställdID (IDENTITY) | Butikspersonal med roll (Butikschef, Säljare, etc) |
| **Recensioner** | RecensionsID (IDENTITY) | Kundrecensioner med betyg 1-5 |
| **LagerSaldo** | (ButikID, ISBN) | Lager per butik – kompositnyckel |

### Junction-tabell (VG – many-many)

| Tabell | Nyckel | Relation |
|--------|--------|----------|
| **BokFörfattare** | (ISBN13, FörfattareID) | Böcker ↔ Författare |

## Vyer och Stored Procedures

### Vyer

```sql
-- TitlarPerFörfattare (G-krav)
SELECT * FROM TitlarPerFörfattare;
-- Returnerar: Namn, Ålder, Titlar, Lagervärde

-- KundOrderÖversikt (VG-krav)
-- Motivering: Vyn aggregerar köphistorik per kund och möjliggör
-- identifiering av VIP-kunder, analys av orderstatus och uppföljning
-- av total omsättning per kund – användbart för marknadsföring och kundvård.
SELECT * FROM KundOrderÖversikt;
-- Returnerar: Kund, Epost, AntalOrdrar, TotaltKöpt, SenastBeställt, AktivaOrdrar
```

### Stored Procedures

```sql
-- Sök böcker (används av Python-appen)
EXEC SökBok @Sökterm = 'Potter';

-- Hämta lagersaldo för ISBN (används av Python-appen)
EXEC HämtaLager @ISBN = '9789113027494';

-- Flytta bok mellan butiker (VG-krav)
-- Transaktion med UPDLOCK/ROWLOCK + XACT_ABORT för säkerhet.
-- Separata felmeddelanden: "Boken finns inte i källbutiken" vs "Otillräckligt lagersaldo".
EXEC FlyttaBok @FrånButikID=1, @TillButikID=2,
               @ISBN='9789113027494', @Antal=3;
```

## Säkerhet – SQL-injection skydd på databasnivå

### Arkitektur

| Nivå | Skydd |
|------|-------|
| **Python** | Anropar enbart `exec SökBok`/`exec HämtaLager`. Ingen SELECT/JOIN/WHERE i kod. |
| **Stored Procedures** | Parametrar har explicita datatyper (`nvarchar(255)`, `char(13)`). Inga dynamiska SQL-strängar. |
| **SQLAlchemy** | `text()` med namngivna parametrar (`:term`, `:isbn`). Bindning separerar data från SQL. |
| **Databas** | `bokhandel_lasare`: `db_datareader` + `EXECUTE` på `SökBok`/`HämtaLager`. Inga DDL-rättigheter. |

### Test

```bash
$ python bokhandel_app.py

Säkerhetstest – SQL-injection:
  Payload: "' OR '1'='1"                         → Skyddad (0 träffar)
  Payload: "'; DROP TABLE Böcker; --"           → Skyddad (0 träffar)
  Payload: "' UNION SELECT * FROM sys.tab..."      → Skyddad (0 träffar)
  Payload: "%' OR 1=1 --"                         → Skyddad (0 träffar)
  Payload: "\x00\x1b; DELETE FROM Kunder..."       → Skyddad (0 träffar)
Alla payload hanterades säkert via parametriserade frågor.
```

## Anslutningskonfiguration

Python-appen använder SQLAlchemy för att ansluta till SQL Server. Konfigurera anslutningen i `bokhandel_app.py`:

### Alternativ 1: SQL Server Authentication (Docker / fjärrserver)

```python
ENGINE = create_engine(
    "mssql+pyodbc://bokhandel_lasare:BokH4ndel!Las4re@localhost,1433/Bokhandel"
    "?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
)
```

### Alternativ 2: Windows Authentication (lokal SQL Server)

```python
ENGINE = create_engine(
    "mssql+pyodbc://@localhost/Bokhandel"
    "?driver=ODBC+Driver+18+for+SQL+Server&Trusted_Connection=yes"
)
```

### Miljövariabler (valfritt)

Skapa en `.env`-fil för säker hantering av credentials:

```bash
# .env
DB_USER=bokhandel_lasare
DB_PASS=BokH4ndel!Las4re
DB_HOST=localhost,1433
DB_NAME=Bokhandel
```

> **Notering för examinator:** Default är Docker-konfigurationen (SQL Auth). Vid körning mot annan server, byt `ENGINE` i början av `bokhandel_app.py`.

## Filer för inlämning

| Fil | Innehåll |
|-----|----------|
| `01_schema.sql` | Databas, 12 tabeller, PK/FK, constraints, index, säkerhet |
| `02_demodata.sql` | Demo data för alla tabeller |
| `03_views_and_sp.sql` | 2 vyer + 3 stored procedures |
| `04_security.sql` | Idempotent login/user/role script (valfritt) |
| `ER_diagram.md` | Mermaid ER-diagram + normaliseringskommentar |
| `bokhandel_app.py` | Python SQLAlchemy-klient med SP-anrop |
| `requirements.txt` | Python dependencies |
| `TaharGuemir.bak` | **Full backup – skickas till ITHSdistans** |

## Återställa från backup

```sql
RESTORE DATABASE Bokhandel
FROM DISK = 'C:\Path\To\TaharGuemir.bak'
WITH REPLACE;
```

## Kontaktperson

Tahar Guemir – ITHS Distans
