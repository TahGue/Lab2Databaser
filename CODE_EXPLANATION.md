# Bokhandel Database – Code Documentation

## Overview

A multi-store bookstore database for ITHS SQL Server assignment implementing G/VG requirements.

---

## File Structure

| File | Purpose | Execution Order |
|------|---------|-----------------|
| `01_schema.sql` | Database creation, tables, keys, indexes, initial security | 1 |
| `02_demodata.sql` | Sample data for all tables | 2 |
| `03_views_and_sp.sql` | Views and stored procedures | 3 |
| `04_security.sql` | Idempotent security setup (optional, can run separately) | 4 |
| `bokhandel_app.py` | Python client application | N/A |

---

## 01_schema.sql – Database Schema

### Database Creation

Creates the `Bokhandel` database with `SQL_Latin1_General_CP1_CI_AS` collation for Swedish character support.

### Tables (12 total)

#### Entity Tables (11)

| Table | Primary Key | Description |
|-------|-------------|-------------|
| **Förlag** | FörlagID (IDENTITY) | Publishers with country and website |
| **Kategorier** | KategoriID (IDENTITY) | Book genres/categories |
| **Författare** | ID (IDENTITY) | Author biographical data |
| **Böcker** | ISBN13 (CHAR(13)) | Book details, FK to Förlag/Kategorier |
| **Butiker** | ButikID (IDENTITY) | Store locations with address info |
| **Kunder** | KundID (IDENTITY) | Customer contact information |
| **Ordrar** | OrderID (IDENTITY) | Order headers with status tracking |
| **OrderRader** | OrderRadID (IDENTITY) | Order line items: book, quantity, price |
| **Anställda** | AnställdID (IDENTITY) | Staff with role constraints |
| **Recensioner** | RecensionsID (IDENTITY) | Book reviews with 1-5 rating |
| **LagerSaldo** | (ButikID, ISBN) | Inventory per store – composite key |

#### Junction Table (1) – VG Requirement

| Table | Key | Relation |
|-------|-----|----------|
| **BokFörfattare** | (ISBN13, FörfattareID) | Many-to-many: Books ↔ Authors |

### Constraints

**CHECK Constraints:**
- ISBN13 must be exactly 13 digits (regex validation)
- Pris >= 0 (no negative prices)
- Sidor > 0 (positive page counts)
- Antal >= 0 (non-negative inventory)
- Omslag must be one of: 'Häftad', 'Inbunden', 'E-bok', 'Ljudbok'
- Status must be one of: 'Mottagen', 'Behandlas', 'Skickad', 'Levererad', 'Avbruten'
- Roll must be one of: 'Butikschef', 'Säljare', 'Lageransvarig', 'Kassör'
- Betyg between 1 and 5 (review rating)
- Postnummer must be exactly 5 digits

**Foreign Key Actions:**
- Most FKs use `ON UPDATE CASCADE` for referential integrity
- `ON DELETE CASCADE` for junction tables to maintain consistency
- `ON DELETE SET NULL` for nullable relationships (book publisher/category)
- `ON DELETE NO ACTION` for order-store relationship to prevent accidental deletion

### Indexes

Created on frequently queried columns:
- `IX_Böcker_Titel` – book title searches
- `IX_Kunder_Epost` – customer email lookups
- `IX_Ordrar_KundID` – customer order history
- `IX_Recensioner_ISBN` – book reviews lookup

### Security

Creates a read-only login/user `bokhandel_lasare`:
- Server login with password
- Database user mapped to login
- Member of `db_datareader` role (SELECT permission on all tables)

---

## 02_demodata.sql – Sample Data

Populates all tables with realistic bookstore data.

### Data Volume

| Table | Records |
|-------|---------|
| Förlag | 5 publishers |
| Kategorier | 6 genres |
| Författare | 8 authors |
| Böcker | 12 books |
| BokFörfattare | 13 relationships (some co-authored) |
| Butiker | 4 stores |
| LagerSaldo | 40+ inventory records |
| Kunder | 6 customers |
| Ordrar | 7 orders |
| OrderRader | 12 line items |
| Anställda | 9 employees |
| Recensioner | 10 reviews |

### Notable Data Patterns

- **Co-authorship**: One book (ISBN 9789163890147) has two authors (Emma Askling + Camilla Läckberg) demonstrating the many-to-many relationship
- **Inventory distribution**: Books spread across all 4 stores with varying quantities
- **Order statuses**: Mix of delivered, shipped, and processing orders
- **Employee roles**: All 4 role types represented across stores

---

## 03_views_and_sp.sql – Views and Stored Procedures

### Views

#### TitlarPerFörfattare (G Requirement)

Aggregates author statistics:
- **Namn**: Full name
- **Ålder**: Calculated age with accurate birthday logic
- **Titlar**: Count of distinct books authored
- **Lagervärde**: Total inventory value across all stores

**Technical Implementation:**
- Uses CTE (BokVärde) to calculate per-book inventory value first
- Prevents double-counting for co-authored books
- Uses `DATEDIFF` with month/day adjustment for accurate age calculation

#### KundOrderÖversikt (VG Requirement)

Customer purchase history summary:
- **KundID**, **Kund**, **Epost**: Customer identification
- **AntalOrdrar**: Total number of orders
- **TotaltKöpt**: Sum of all purchases
- **SenastBeställt**: Date of most recent order
- **AktivaOrdrar**: Count of non-delivered/non-cancelled orders

**Use Case:**
Enables quick identification of VIP customers, tracking ongoing orders, and targeted marketing without complex multi-table queries.

### Stored Procedures

#### FlyttaBok (VG Requirement)

Safely transfers book inventory between stores.

**Parameters:**
- `@FrånButikID` – Source store ID
- `@TillButikID` – Destination store ID  
- `@ISBN` – Book ISBN
- `@Antal` – Quantity to move (default 1)

**Validation Steps:**
1. Verify `@Antal > 0`
2. Verify source ≠ destination
3. Verify both stores exist
4. Verify book exists

**Transaction Safety:**
1. Uses `UPDLOCK + ROWLOCK` on source inventory row
2. Checks for existing book in source store
3. Verifies sufficient quantity
4. Updates source inventory (decrement)
5. Upserts destination inventory (increment or insert)
6. Commits on success, auto-rollback on error via `XACT_ABORT ON`

**Output:**
Prints confirmation message with book title and store names.

#### SökBok

Searches books by title with author aggregation.

**Parameters:**
- `@Sökterm nvarchar(255)` – Search term (default '%' for all)

**Returns:**
- Book details (ISBN, title, language, price, publication date)
- Concatenated author names
- Category and publisher names

**Security:**
Python app calls only this SP – no direct SELECT on tables. The `@Sökterm` is typed (nvarchar), not concatenated into SQL.

#### HämtaLager

Retrieves inventory per store for a specific book.

**Parameters:**
- `@ISBN char(13)` – Book ISBN

**Returns:**
Store name, city, and quantity for each location carrying the book.

### Security Grants

Gives `bokhandel_lasare` EXECUTE permission on all three stored procedures. This follows the pattern from the teacher's `UserDemo.sql`: a read-only user can perform controlled writes through validated stored procedures.

---

## 04_security.sql – Idempotent Security Setup

Can be run separately after schema creation to set up or verify security.

**Idempotent Checks:**
1. `IF NOT EXISTS` on `sys.server_principals` – creates login only if missing
2. `IF NOT EXISTS` on `sys.database_principals` – creates user only if missing
3. `IF NOT EXISTS` on role membership – adds to role only if not already member

This allows safe re-execution without errors.

---

## bokhandel_app.py – Python Client

### Architecture

A SQLAlchemy-based client that demonstrates database-level SQL injection protection.

**Core Principle:**
The Python code contains **zero** SELECT, JOIN, or WHERE clauses. All SQL logic lives in the database stored procedures.

### Dependencies

- `sqlalchemy>=2.0` – Database abstraction
- `pyodbc>=5.0` – SQL Server driver
- `python-dotenv>=1.0` – Environment variable management

### Configuration

Uses `.env` file (ignored by git) for credentials:

```
DB_SERVER=localhost,1433
DB_NAME=Bokhandel
DB_USER=bokhandel_lasare
DB_PASSWORD=your_password
```

Fallback to `getpass()` prompt if `.env` not found (teacher's pattern).

### Functions

#### `sok_bocker(sokterm)`

Calls `exec SökBok` with parameterized input, then `exec HämtaLager` for each result to build complete book info with inventory.

**Security:**
- Uses `text("exec SökBok @Sökterm = :term")` with dict binding
- `:term` is never concatenated into SQL string
- Type safety via SP parameter `@Sökterm nvarchar(255)`

#### `skriv_ut_bok(bok)`

Pretty-prints book information including inventory breakdown.

#### `test_injection_skydd()`

Automated security test that attempts 5 classic SQL injection payloads:
1. `' OR '1'='1` – boolean bypass
2. `'; DROP TABLE Böcker; --` – destructive command
3. `' UNION SELECT * FROM sys.tables --` – data extraction
4. `%' OR 1=1 --` – wildcard injection
5. `\x00\x1b; DELETE FROM Kunder;` – control character attack

All payloads are handled safely because input is treated as data, not SQL.

### Execution Flow

1. Load environment variables
2. Build connection string with `URL.create()`
3. Test database connection
4. Run injection protection demonstration
5. Interactive search loop

---

## Security Model

### Multi-Layer SQL Injection Protection

| Layer | Implementation |
|-------|---------------|
| **Network** | Parameterized queries only – no string concatenation |
| **Database** | All logic in typed stored procedures |
| **Permissions** | `bokhandel_lasare` has only `db_datareader` + EXECUTE |
| **Validation** | SP parameters have explicit types and constraints |

### Data Integrity Mechanisms

| Feature | Implementation |
|---------|---------------|
| **Referential integrity** | Foreign keys with CASCADE actions |
| **Business rules** | CHECK constraints on all critical fields |
| **Race condition prevention** | `UPDLOCK + ROWLOCK` in FlyttaBok |
| **Transaction safety** | `XACT_ABORT ON` with explicit transactions |
| **Input validation** | Parameter types and bounds checking |

---

## Normalization

Database is in **3NF/BCNF**:

- **1NF**: All columns atomic, no repeating groups
- **2NF**: Full functional dependency on PK (no partial dependencies)
- **3NF**: No transitive dependencies (non-key attributes depend only on key)
- **BCNF**: Every determinant is a candidate key

Junction table `BokFörfattare` properly implements the many-to-many relationship without redundancy.
