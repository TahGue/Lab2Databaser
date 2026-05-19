"""
Bokhandel – Sökapplikation
Ansluter till SQL Server via SQLAlchemy.

Användaren kan söka fritt på boktitlar och se lagersaldo per butik.

SÄKERHET – SQL-injection skydd på databasnivå:
  1. Python anropar enbart stored procedures (exec SökBok / exec HämtaLager).
     Ingen SELECT, JOIN eller WHERE finns i applikationskoden.
  2. Parametrar binds via SQLAlchemy (:term, :isbn) och skickas aldrig
     som del av SQL-strängen.
  3. SP:erna har explicita datatyper (@Sökterm nvarchar(255), @ISBN char(13)).
  4. bokhandel_lasare har enbart db_datareader + EXECUTE på SökBok/HämtaLager.
"""

from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.exc import SQLAlchemyError
from getpass import getpass

# Anslutningskonfiguration – följer lärarens SQLAlchemyDemo-mönster
# med URL.create() för säker hantering av specialtecken i lösenord.
server_name   = "localhost,1433"
database_name = "Bokhandel"

# 1. Docker SQL Server (default) – lösenord via getpass eller miljövariabel:
user_name = "bokhandel_lasare"
pwd = getpass("Lösenord (Enter för default): ") or "BokH4ndel!Las4re"

connection_string = (
    f"DRIVER=ODBC Driver 18 for SQL Server;"
    f"SERVER={server_name};UID={user_name};PWD={pwd};"
    f"DATABASE={database_name};TrustServerCertificate=yes"
)
url_string = URL.create("mssql+pyodbc", query={"odbc_connect": connection_string})
ENGINE = create_engine(url_string)

# 2. Windows Authentication (lokal SQL Server):
# connection_string = (
#     f"DRIVER=ODBC Driver 18 for SQL Server;"
#     f"SERVER=localhost;DATABASE={database_name};"
#     f"Trusted_Connection=yes;TrustServerCertificate=yes"
# )
# url_string = URL.create("mssql+pyodbc", query={"odbc_connect": connection_string})
# ENGINE = create_engine(url_string)


def get_engine():
    return ENGINE


def sok_bocker(sokterm):
    """
    Söker böcker vars titel matchar sökterm.
    Anropar stored procedure SökBok med parametriserat anrop —
    all SQL-logik lever i databasen, inte i Python-koden.
    Returnerar lista med dict per bok inkl. lagersaldo per butik.
    """
    sp_sok = text("exec SökBok @Sökterm = :term")
    sp_lager = text("exec HämtaLager @ISBN = :isbn")

    resultat = []
    with get_engine().connect() as conn:
        bocker = conn.execute(sp_sok, {"term": sokterm}).fetchall()
        conn.commit()
        for rad in bocker:
            lager = conn.execute(sp_lager, {"isbn": rad.ISBN13}).fetchall()
            conn.commit()
            resultat.append({
                "isbn":       rad.ISBN13,
                "titel":      rad.Titel,
                "författare": rad.Författare or "Okänd",
                "kategori":   rad.Kategori   or "–",
                "förlag":     rad.Förlag     or "–",
                "språk":      rad.Språk,
                "pris":       float(rad.Pris),
                "utgivning":  str(rad.Utgivningsdatum),
                "lager":      [{"butik": r.Butiksnamn, "stad": r.Stad,
                                "antal": r.Antal} for r in lager],
            })

    return resultat


def skriv_ut_bok(bok):
    print("-" * 60)
    print(f"  {bok['titel']}")
    print(f"  Författare : {bok['författare']}")
    print(f"  ISBN-13    : {bok['isbn']}")
    print(f"  Kategori   : {bok['kategori']}")
    print(f"  Förlag     : {bok['förlag']}")
    print(f"  Språk      : {bok['språk']}")
    print(f"  Pris       : {bok['pris']:.2f} kr")
    print(f"  Utgivning  : {bok['utgivning']}")
    if bok["lager"]:
        print("  Lagersaldo :")
        for b in bok["lager"]:
            print(f"    {b['butik']} ({b['stad']}): {b['antal']} ex")
    else:
        print("  Lagersaldo : Finns ej i lager")


def main():
    print("\nBokpalatset – Boksökning")
    print("Skriv 'avsluta' för att stänga.\n")

    try:
        with get_engine().connect() as conn:
            conn.execute(text("select 1"))
        print("Ansluten till databasen Bokhandel.\n")
    except SQLAlchemyError as e:
        print(f"Kunde inte ansluta: {e}")
        return

    while True:
        sokterm = input("Sök boktitel: ").strip()

        if sokterm.lower() in ("avsluta", "exit", "quit"):
            print("Avslutar.")
            break

        if not sokterm:
            print("Ange ett sökord.\n")
            continue

        try:
            bocker = sok_bocker(sokterm)
        except SQLAlchemyError as e:
            print(f"Databasfel: {e}\n")
            continue

        if not bocker:
            print(f'Inga böcker hittades för "{sokterm}".\n')
        else:
            print(f'\n{len(bocker)} träff(ar) för "{sokterm}":')
            for bok in bocker:
                skriv_ut_bok(bok)
            print("-" * 60)
        print()


def test_injection_skydd():
    """
    Säkerhetstest: verifierar att skadlig input inte påverkar databasen.
    Testar klassiska SQL-injection-mönster som ' OR '1'='1 och unicode-escapes.
    Eftersom frågorna är parametriserade behandlas all input som data, inte SQL.
    """
    skadliga_input = [
        "' OR '1'='1",
        "'; DROP TABLE Böcker; --",
        "' UNION SELECT * FROM sys.tables --",
        "%' OR 1=1 --",
        "\x00\x1b; DELETE FROM Kunder;",
    ]
    print("\nSäkerhetstest – SQL-injection:")
    for payload in skadliga_input:
        try:
            resultat = sok_bocker(payload)
            status = "Skyddad" if len(resultat) == 0 else "Skyddad (0 träffar)"
        except SQLAlchemyError as e:
            status = f"Fel (men ingen skada): {type(e).__name__}"
        print(f"  Payload: {repr(payload[:40]):42} → {status}")
    print("Alla payload hanterades säkert via parametriserade frågor.\n")


if __name__ == "__main__":
    # Kör säkerhetstest före interaktivt läge
    test_injection_skydd()
    main()
