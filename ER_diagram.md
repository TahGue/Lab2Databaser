# ER-Diagram – Bokhandel

**Tahar Guemir – ITHS Distans**  
**12 tabeller** (11 entiteter + 1 junction) | **3 stored procedures** | **2 vyer** | **3NF-normaliserad**

---

## Entity-Relationship Diagram (Mermaid)

```mermaid
erDiagram

    FORLAG {
        int      FörlagID     PK
        nvarchar Namn
        nvarchar Land
        nvarchar Webbplats
    }

    KATEGORIER {
        int      KategoriID   PK
        nvarchar Namn         UK
        nvarchar Beskrivning
    }

    FORFATTARE {
        int      ID            PK
        nvarchar Förnamn
        nvarchar Efternamn
        date     Födelsedatum
        nvarchar Nationalitet
    }

    BOCKER {
        char     ISBN13         PK
        nvarchar Titel
        nvarchar Språk
        decimal  Pris          "CHECK >= 0"
        date     Utgivningsdatum
        nvarchar Omslag         "CHECK enum"
        smallint Sidor          "CHECK > 0"
        int      FörlagID       FK
        int      KategoriID     FK
    }

    BOKFORFATTARE {
        char ISBN13         PK, FK
        int  FörfattareID   PK, FK
    }

    BUTIKER {
        int      ButikID      PK
        nvarchar Butiksnamn
        nvarchar Gatuadress
        char     Postnummer   "CHECK numeric"
        nvarchar Stad
        nvarchar Telefon
    }

    LAGERSALDO {
        int      ButikID   PK, FK
        char     ISBN      PK, FK
        smallint Antal     "CHECK >= 0"
    }

    KUNDER {
        int      KundID      PK
        nvarchar Förnamn
        nvarchar Efternamn
        nvarchar Epost      UK
        nvarchar Telefon
        nvarchar Gatuadress
        char     Postnummer
        nvarchar Stad
        date     Registrerad "DEFAULT getdate()"
    }

    ORDRAR {
        int       OrderID      PK
        int       KundID       FK
        int       ButikID      FK
        datetime2 Orderdatum   "DEFAULT getdate()"
        nvarchar  Status       "CHECK enum"
        decimal   TotalBelopp
    }

    ORDERRADER {
        int      OrderRadID  PK
        int      OrderID     FK
        char     ISBN        FK
        smallint Antal       "CHECK > 0"
        decimal  Enhetspris  "CHECK >= 0"
    }

    ANSTALLDA {
        int      AnställdID  PK
        int      ButikID     FK
        nvarchar Förnamn
        nvarchar Efternamn
        nvarchar Epost      UK
        nvarchar Telefon
        nvarchar Roll       "CHECK enum"
        date     Anställd   "DEFAULT getdate()"
    }

    RECENSIONER {
        int       RecensionsID PK
        char      ISBN13       FK
        int       KundID       FK
        tinyint   Betyg        "CHECK 1-5"
        nvarchar  Kommentar
        datetime2 Datum        "DEFAULT getdate()"
    }

    %% Relationer
    FORLAG        ||--o{  BOCKER         : "ger ut"
    KATEGORIER    ||--o{  BOCKER         : "tillhör"
    BOCKER        ||--o{  BOKFORFATTARE  : "skrivs av"
    FORFATTARE    ||--o{  BOKFORFATTARE  : "skriver"
    BOCKER        ||--o{  LAGERSALDO     : "finns i"
    BUTIKER       ||--o{  LAGERSALDO     : "lagrar"
    BUTIKER       ||--o{  ORDRAR         : "tar emot"
    KUNDER        ||--o{  ORDRAR         : "lägger"
    ORDRAR        ||--o{  ORDERRADER     : "innehåller"
    BOCKER        ||--o{  ORDERRADER     : "beställs via"
    BUTIKER       ||--o{  ANSTALLDA      : "anställer"
    BOCKER        ||--o{  RECENSIONER    : "recenseras i"
    KUNDER        ||--o{  RECENSIONER    : "skriver"
```

---

## Förklaring av notation

| Symbol | Betydelse |
|--------|-----------|
| **PK** | Primärnyckel (Primary Key) |
| **FK** | Främmande nyckel (Foreign Key) |
| **UK** | Unik nyckel (Unique Key) |
| `||--o{` | En-till-många relation (1:N) |
| **CHECK** | Integritetsvillkor (constraints) |
| **DEFAULT** | Förvalt värde |

---

## Tabellöversikt

### Entitetstabeller (11 st)

| # | Tabell | Primärnyckel | Beskrivning | Tillval |
|---|--------|--------------|-------------|---------|
| 1 | **Förlag** | FörlagID (IDENTITY) | Bokförlag med land och webbplats | Extra |
| 2 | **Kategorier** | KategoriID (IDENTITY) | Bokgenrer med unikt namn | Extra |
| 3 | **Författare** | ID (IDENTITY) | Persondata: namn, födelse, nationalitet | G-krav |
| 4 | **Böcker** | ISBN13 (CHAR(13), CHECK) | Bokinformation: titel, pris, datum, omslag | G-krav |
| 5 | **Butiker** | ButikID (IDENTITY) | Butiker med fullständig adress | G-krav |
| 6 | **Kunder** | KundID (IDENTITY) | Kundregister med kontaktuppgifter | Extra |
| 7 | **Ordrar** | OrderID (IDENTITY) | Orderheader med status och datum | Extra |
| 8 | **OrderRader** | OrderRadID (IDENTITY) | Orderrader: bok, antal, historiskt pris | Extra |
| 9 | **Anställda** | AnställdID (IDENTITY) | Butikspersonal med roll | Extra (VG+) |
| 10 | **Recensioner** | RecensionsID (IDENTITY) | Kundrecensioner med betyg 1-5 | Extra (VG+) |
| 11 | **LagerSaldo** | (ButikID, ISBN) | Lager per butik – kompositnyckel | G-krav |

### Junction-tabell (VG – many-many)

| Tabell | Nycklar | Relation | Kommentar |
|--------|---------|----------|-----------|
| **BokFörfattare** | (ISBN13, FörfattareID) PK | Böcker ↔ Författare | Möjliggör flera författare per bok |

---

## Vyer

| Vy | Kolumner | Beskrivning |
|----|----------|-------------|
| **TitlarPerFörfattare** | Namn, Ålder, Titlar, Lagervärde | Sammanställning per författare. CTE mot dubbelräkning. **(G-krav)** |
| **KundOrderÖversikt** | Kund, Epost, AntalOrdrar, TotaltKöpt, SenastBeställt, AktivaOrdrar | Köphistorik per kund. Aggregering över Ordrar + OrderRader. **(VG-krav)** |

---

## Stored Procedures

| Procedure | Parametrar | Syfte |
|-----------|------------|-------|
| **SökBok** | `@Sökterm nvarchar(255)` | Söker böcker på titel. Används av Python-app. **(Säkerhet: DB-nivå SQL-injection skydd)** |
| **HämtaLager** | `@ISBN char(13)` | Returnerar lagersaldo per butik för given bok. Används av Python-app. |
| **FlyttaBok** | `@FrånButikID int`, `@TillButikID int`, `@ISBN char(13)`, `@Antal smallint=1` | Flyttar bok mellan butiker med transaktion, locking och validering. **(VG-krav)** |

---

## Normaliseringskommentar (3NF)

| Regel | Tillämpning |
|-------|-------------|
| **1NF** | Alla attribut är atomära. Ingen upprepad data. |
| **2NF** | Alla icke-nyckelattribut beror på **hela** primärnyckeln. `LagerSaldo.Antal` beror på `(ButikID, ISBN)`. |
| **3NF** | Inga **transitiva** beroenden. Adress lagras i `Butiker`/`Kunder`, inte dupliceras i `Ordrar`. `OrderRader.Enhetspris` lagras explicit för historisk prisbild (beror inte på `Böcker.Pris`). |
| **BCNF** | Varje determinant är kandidatnyckel. Alla FK-relationer har explicita `ON UPDATE`/`ON DELETE` regler. |

### Exempel på 3NF i praktiken

- `Ordrar` innehåller inte kundens adress – den hämtas från `Kunder` vid behov.
- `OrderRader` lagrar `Enhetspris` separat från `Böcker.Pris` för att bevara historisk prisinformation.
- `BokFörfattare` junction-tabell undviker att lagra författardata i `Böcker` eller vice versa.

---

## Säkerhet – Databasnivå

| Komponent | Skydd |
|-----------|-------|
| **Login** | `bokhandel_lasare` – dedikerad läsanvändare |
| **Roller** | `db_datareader` + `EXECUTE` på `SökBok`/`HämtaLager` |
| **Constraints** | `CHECK` på ISBN (13 siffror), pris (>=0), betyg (1-5), etc. |
| **Referential Integrity** | Alla FK med explicita `ON UPDATE`/`ON DELETE` |
| **SQL Injection** | All SELECT-logik i stored procedures. Python anropar enbart `exec Procedure @Param = :value`. |
