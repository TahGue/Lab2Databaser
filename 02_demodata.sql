use Bokhandel;
go

insert into Förlag (Namn, Land, Webbplats) values
    ('Norstedts',       'Sverige', 'https://www.norstedts.se'),
    ('Albert Bonniers', 'Sverige', 'https://www.albertbonniers.se'),
    ('Piratförlaget',   'Sverige', 'https://www.piratforlaget.se'),
    ('Penguin Books',   'UK',      'https://www.penguin.co.uk'),
    ('HarperCollins',   'USA',     'https://www.harpercollins.com');

insert into Kategorier (Namn, Beskrivning) values
    ('Skönlitteratur', 'Romaner, noveller och poesi'),
    ('Thriller',       'Spänningsromaner och deckare'),
    ('Fantasy',        'Fantasyromaner och science fiction'),
    ('Barn & Ungdom',  'Böcker för barn och ungdomar'),
    ('Facklitteratur', 'Biografier, historia och vetenskap'),
    ('Klassiker',      'Tidlösa litterära verk');

insert into Författare (Förnamn, Efternamn, Födelsedatum, Nationalitet) values
    ('Stieg',       'Larsson',  '1954-08-15', 'Svensk'),
    ('Astrid',      'Lindgren', '1907-11-14', 'Svensk'),
    ('Jo',          'Nesbø',    '1960-03-29', 'Norsk'),
    ('J.K.',        'Rowling',  '1965-07-31', 'Brittisk'),
    ('Emma',        'Askling',  '1982-04-12', 'Svensk'),
    ('John',        'Grisham',  '1955-02-08', 'Amerikansk'),
    ('Camilla',     'Läckberg', '1974-08-30', 'Svensk'),
    ('George R.R.', 'Martin',   '1948-09-20', 'Amerikansk');

insert into Böcker (ISBN13, Titel, Språk, Pris, Utgivningsdatum, Omslag, Sidor, FörlagID, KategoriID) values
    ('9789113027494', 'Män som hatar kvinnor',                    'Svenska', 189.00, '2005-08-01', 'Häftad',  672, 3, 2),
    ('9789113027500', 'Flickan som lekte med elden',              'Svenska', 189.00, '2006-01-01', 'Häftad',  736, 3, 2),
    ('9789113027517', 'Luftslottet som sprängdes',                'Svenska', 189.00, '2007-05-01', 'Häftad',  752, 3, 2),
    ('9789129688313', 'Pippi Långstrump',                         'Svenska',  99.00, '1945-11-26', 'Inbunden',160, 1, 4),
    ('9789129688320', 'Emil i Lönneberga',                        'Svenska',  99.00, '1963-10-01', 'Inbunden',176, 1, 4),
    ('9780747532699', 'Harry Potter och de vises sten',           'Svenska', 159.00, '1997-06-26', 'Häftad',  320, 2, 3),
    ('9780747538493', 'Harry Potter och hemligheternas kammare',  'Svenska', 159.00, '1998-07-02', 'Häftad',  352, 2, 3),
    ('9789174292343', 'Snömannen',                                'Svenska', 179.00, '2007-10-01', 'Häftad',  560, 1, 2),
    ('9789174292350', 'Flaggermusmannen',                         'Svenska', 159.00, '1997-01-01', 'Häftad',  384, 1, 2),
    ('9789163890123', 'Mördaren utan ansikte',                    'Svenska', 169.00, '2022-03-15', 'Häftad',  410, 3, 2),
    ('9789163890130', 'Sommarnattens hemlighet',                  'Svenska', 179.00, '2023-06-01', 'Häftad',  380, 3, 1),
    ('9789163890147', 'Ispalatset i Stockholm',                   'Svenska', 199.00, '2024-01-10', 'Inbunden',450, 2, 1);

insert into BokFörfattare (ISBN13, FörfattareID) values
    ('9789113027494', 1),
    ('9789113027500', 1),
    ('9789113027517', 1),
    ('9789129688313', 2),
    ('9789129688320', 2),
    ('9780747532699', 4),
    ('9780747538493', 4),
    ('9789174292343', 3),
    ('9789174292350', 3),
    ('9789163890123', 5),
    ('9789163890130', 5),
    ('9789163890147', 5),
    ('9789163890147', 7);

insert into Butiker (Butiksnamn, Gatuadress, Postnummer, Stad, Telefon) values
    ('Bokpalatset Stockholm', 'Drottninggatan 12', '11151', 'Stockholm', '08-123 45 67'),
    ('Bokpalatset Göteborg',  'Avenyn 45',         '41136', 'Göteborg',  '031-234 56 78'),
    ('Bokpalatset Malmö',     'Stortorget 3',      '21122', 'Malmö',     '040-345 67 89'),
    ('Bokpalatset Uppsala',   'Stora Torget 8',    '75310', 'Uppsala',   '018-456 78 90');

insert into LagerSaldo (ButikID, ISBN, Antal) values
    (1, '9789113027494', 12), (1, '9789113027500',  8), (1, '9789113027517',  6),
    (1, '9789129688313', 15), (1, '9789129688320', 10),
    (1, '9780747532699', 20), (1, '9780747538493', 18),
    (1, '9789174292343',  7), (1, '9789174292350',  5),
    (1, '9789163890123',  9), (1, '9789163890130',  4), (1, '9789163890147',  3),

    (2, '9789113027494', 10), (2, '9789113027500',  6), (2, '9789113027517',  4),
    (2, '9789129688313', 12), (2, '9789129688320',  8),
    (2, '9780747532699', 15), (2, '9780747538493', 12),
    (2, '9789174292343',  5), (2, '9789174292350',  3),
    (2, '9789163890123',  7), (2, '9789163890130',  2), (2, '9789163890147',  1),

    (3, '9789113027494',  8), (3, '9789113027500',  5), (3, '9789113027517',  3),
    (3, '9789129688313',  9), (3, '9789129688320',  6),
    (3, '9780747532699', 11), (3, '9780747538493',  9),
    (3, '9789174292343',  4), (3, '9789174292350',  2),
    (3, '9789163890123',  6), (3, '9789163890130',  3), (3, '9789163890147',  2),

    (4, '9789113027494',  5), (4, '9789113027500',  3),
    (4, '9789129688313',  7), (4, '9789129688320',  4),
    (4, '9780747532699',  8),
    (4, '9789174292343',  3),
    (4, '9789163890123',  4), (4, '9789163890130',  1), (4, '9789163890147',  1);

insert into Kunder (Förnamn, Efternamn, Epost, Telefon, Gatuadress, Postnummer, Stad) values
    ('Anna',   'Svensson',  'anna.svensson@epost.se', '070-111 22 33', 'Kungsgatan 5',     '11122', 'Stockholm'),
    ('Erik',   'Johansson', 'erik.j@webmail.se',      '073-222 33 44', 'Vasagatan 10',     '41126', 'Göteborg'),
    ('Maria',  'Nilsson',   'maria.nilsson@post.se',  '072-333 44 55', 'Södergatan 18',    '21135', 'Malmö'),
    ('Lars',   'Karlsson',  'lars.k@hempost.se',       null,           'Torggatan 3',      '75302', 'Uppsala'),
    ('Sofia',  'Lindqvist', 'sofia.l@surfmail.se',    '076-444 55 66', 'Birger Jarlsg 7',  '11457', 'Stockholm'),
    ('Mikael', 'Berg',      'mikael.berg@npost.se',   '070-555 66 77', 'Haga Nygata 22',   '41301', 'Göteborg');

insert into Ordrar (KundID, ButikID, Orderdatum, Status, TotalBelopp) values
    (1, 1, '2024-01-15 10:30:00', 'Levererad', 348.00),
    (2, 2, '2024-02-20 14:00:00', 'Levererad', 159.00),
    (3, 3, '2024-03-05 09:15:00', 'Levererad', 447.00),
    (1, 1, '2024-04-10 16:45:00', 'Skickad',   189.00),
    (4, 4, '2024-05-12 11:20:00', 'Behandlas', 358.00),
    (5, 1, '2024-06-01 13:00:00', 'Mottagen',  179.00),
    (6, 2, '2024-06-03 08:30:00', 'Mottagen',  348.00);

insert into OrderRader (OrderID, ISBN, Antal, Enhetspris) values
    (1, '9789113027494', 1, 189.00),
    (1, '9789113027500', 1, 159.00),
    (2, '9780747532699', 1, 159.00),
    (3, '9789129688313', 1,  99.00),
    (3, '9789174292343', 1, 179.00),
    (3, '9789163890123', 1, 169.00),
    (4, '9789113027494', 1, 189.00),
    (5, '9789113027500', 1, 189.00),
    (5, '9780747538493', 1, 159.00),
    (6, '9789174292343', 1, 179.00),
    (7, '9789113027494', 1, 189.00),
    (7, '9789113027500', 1, 159.00);

insert into Anställda (ButikID, Förnamn, Efternamn, Epost, Telefon, Roll, Anställd) values
    (1, 'Eva',       'Holm',        'eva.holm@bokpalatset.se',    '070-111 11 11', 'Butikschef',    '2020-03-01'),
    (1, 'Patrik',    'Lundin',      'patrik.l@bokpalatset.se',    '070-222 22 22', 'Säljare',       '2021-06-15'),
    (1, 'Lisa',      'Bergqvist',   'lisa.b@bokpalatset.se',      '070-333 33 33', 'Kassör',        '2022-01-10'),
    (2, 'Mats',      'Åkesson',     'mats.a@bokpalatset.se',      '073-444 44 44', 'Butikschef',    '2019-08-01'),
    (2, 'Sara',      'Nordin',      'sara.n@bokpalatset.se',       null,           'Lageransvarig', '2023-02-01'),
    (3, 'Karin',     'Eriksson',    'karin.e@bokpalatset.se',     '072-555 55 55', 'Butikschef',    '2021-11-01'),
    (3, 'Anders',    'Svensson',    'anders.s@bokpalatset.se',    '076-666 66 66', 'Säljare',       '2022-09-01'),
    (4, 'Nina',      'Johansson',   'nina.j@bokpalatset.se',       null,           'Butikschef',    '2020-05-01'),
    (4, 'Fredrik',   'Dahl',        'fredrik.d@bokpalatset.se',   '070-777 77 77', 'Säljare',       '2023-03-15');

insert into Recensioner (ISBN13, KundID, Betyg, Kommentar, Datum) values
    ('9789113027494', 1, 5, 'En av de bästa deckare jag läst. Spännande från första sidan!',        '2024-02-01 10:00:00'),
    ('9789113027494', 2, 4, 'Mycket bra, men något långsam i mitten.',                         '2024-02-10 14:30:00'),
    ('9780747532699', 3, 5, 'Magisk! Min son älskade den.',                                      '2024-03-01 09:15:00'),
    ('9780747532699', 1, 5, 'En klassiker som aldrig blir gammal.',                              '2024-03-05 16:45:00'),
    ('9789129688313', 4, 4, 'Barnbarnet älskar Pippi. En riktig klassiker.',                    '2024-01-20 11:00:00'),
    ('9789174292343', 5, 3, 'Bra men inte Nesbøs bästa.',                                       '2024-04-02 13:20:00'),
    ('9789163890123', 6, 4, 'Spännande svensk deckare. Rekommenderas!',                          '2024-05-10 10:00:00'),
    ('9789163890147', 2, 5, 'Fantastisk miljöbeskrivning av Stockholm. Läsvärd!',               '2024-05-15 18:30:00'),
    ('9789113027517', 3, 4, 'Bra avslutning på trilogin.',                                       '2024-06-01 12:00:00'),
    ('9780747538493', 5, 5, 'Ännu bättre än första boken!',                                     '2024-06-10 15:00:00');
go
