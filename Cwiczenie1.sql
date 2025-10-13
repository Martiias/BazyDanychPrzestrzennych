/*
--1.Utwórz now¹ bazê danych nazywaj¹c j¹ firma.
CREATE DATABASE firma;
GO
USE firma;
GO
--2.Dodaj schemat o nazwie ksiegowosc
CREATE SCHEMA ksiegowosc;
GO
*/
--3.Dodaj cztery tabele:
/*
• pracownicy (id_pracownika, imie, nazwisko, adres, telefon) 
• godziny (id_godziny, data, liczba_godzin , id_pracownika) 
• pensja (id_pensji, stanowisko, kwota) 
• premia (id_premii, rodzaj, kwota) 
• wynagrodzenie ( id_wynagrodzenia, data, id_pracownika, id_godziny, id_pensji, id_premii) 
przyjmuj¹c nastêpuj¹ce za³o¿enia:
 i. typy atrybutów maj¹ zostaæ dobrane tak, aby sk³adowanie danych by³o optymalne,
ii. klucz g³ówny dla ka¿dej tabeli oraz klucze obce tam, gdzie wystêpuj¹ powi¹zania pomiêdzy tabelami, 
iii. opisy/komentarze dla ka¿dej tabeli – u¿yj polecenia COMMENT 
U¿ywam SQL Server i nie ma tutaj polecenia COMMENT, ale analogicznym poleceniem jest: EXEC sp_addextendedproperty 
*/
/*
--Tabela pracownicy

CREATE TABLE ksiegowosc.pracownicy (
    id_pracownika INT IDENTITY(1,1) PRIMARY KEY,
    imie NVARCHAR(50) NOT NULL,
    nazwisko NVARCHAR(50) NOT NULL,
    adres NVARCHAR(150),
    telefon NVARCHAR(15)
);
EXEC sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Tabela przechowuje dane o pracownikach firmy', 
@level0type = N'SCHEMA', @level0name = 'ksiegowosc', 
@level1type = N'TABLE',  @level1name = 'pracownicy';
GO

--Tabela godziny

CREATE TABLE ksiegowosc.godziny (
    id_godziny INT IDENTITY(1,1) PRIMARY KEY,
    data DATE NOT NULL,
    liczba_godzin DECIMAL(6,2) NOT NULL,
    id_pracownika INT NOT NULL,
    FOREIGN KEY (id_pracownika) REFERENCES ksiegowosc.pracownicy(id_pracownika)
);
EXEC sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Tabela przechowuje informacje o przepracowanych godzinach pracowników', 
@level0type = N'SCHEMA', @level0name = 'ksiegowosc', 
@level1type = N'TABLE',  @level1name = 'godziny';
GO

--Tabela pensja 

CREATE TABLE ksiegowosc.pensja (
    id_pensji INT IDENTITY(1,1) PRIMARY KEY,
    stanowisko NVARCHAR(50) NOT NULL,
    kwota DECIMAL(10,2) NOT NULL
);
EXEC sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Tabela przechowuje informacje o pensjach',
@level0type = N'SCHEMA', @level0name = 'ksiegowosc', 
@level1type = N'TABLE',  @level1name = 'pensja';
GO

--Tabela premia

CREATE TABLE ksiegowosc.premia (
    id_premii INT IDENTITY(1,1) PRIMARY KEY,
    rodzaj NVARCHAR(50),
    kwota DECIMAL(10,2)
);
EXEC sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Tabela przechowuje informacje o premiach', 
@level0type = N'SCHEMA', @level0name = 'ksiegowosc', 
@level1type = N'TABLE',  @level1name = 'premia';
GO

--Tabela wynagrodzenie

CREATE TABLE ksiegowosc.wynagrodzenie (
    id_wynagrodzenia INT IDENTITY(1,1) PRIMARY KEY,
    data DATE NOT NULL,
    id_pracownika INT NOT NULL,
    id_godziny INT NOT NULL,
    id_pensji INT NOT NULL,
    id_premii INT NULL,
    FOREIGN KEY (id_pracownika) REFERENCES ksiegowosc.pracownicy(id_pracownika),
    FOREIGN KEY (id_godziny) REFERENCES ksiegowosc.godziny(id_godziny),
    FOREIGN KEY (id_pensji) REFERENCES ksiegowosc.pensja(id_pensji),
    FOREIGN KEY (id_premii) REFERENCES ksiegowosc.premia(id_premii)
);
EXEC sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Tabela ³¹czy dane o wynagrodzeniach pracowników', 
@level0type = N'SCHEMA', @level0name = 'ksiegowosc', 
@level1type = N'TABLE',  @level1name = 'wynagrodzenie';
GO
*/

--4.Wype³nij ka¿d¹ tabelê 10. rekordami.
/*
-- Pracownicy
INSERT INTO ksiegowosc.pracownicy (imie, nazwisko, adres, telefon) VALUES
('Jan', 'Nowak', 'Gdañsk', '515096244'),
('Anna', 'Kowalska', 'Kraków', '515865098'),
('Karol', 'Wiœniewski', 'Kraków', '516289033'),
('Julia', 'Nowicka', 'Katowice', '545675323'),
('Micha³', 'Lewandowski', 'Wroc³aw', '634547676'),
('Ilona', 'Kamiñska', '£ódŸ', '543567437'),
('Jacek', 'Zieliñski', 'Warszawa', '578912564'),
('Katarzyna', 'Nowak', 'Lublin', '642896454'),
('Tomasz', 'Wójcik', 'Tarnów', '649356123'),
('Karolina', 'Kaczmarek', 'Rzeszów', '546113098');
GO

-- Godziny
INSERT INTO ksiegowosc.godziny (data, liczba_godzin, id_pracownika) VALUES
('2025-09-01', 160, 1),
('2025-09-01', 170, 2),
('2025-09-01', 150, 3),
('2025-09-01', 180, 4),
('2025-09-01', 160, 5),
('2025-09-01', 175, 6),
('2025-09-01', 160, 7),
('2025-09-01', 165, 8),
('2025-09-01', 155, 9),
('2025-09-01', 170, 10);
GO

-- Pensja
INSERT INTO ksiegowosc.pensja (stanowisko, kwota) VALUES
('kierownik', 5000),
('ksiêgowy', 2800),
('analityk', 3200),
('specjalista', 2700),
('asystent', 2000),
('koordynator', 2400),
('informatyk', 3000),
('magazynier', 1800),
('sprzedawca', 2200),
('sekretarka', 2100);
GO

-- Premia
INSERT INTO ksiegowosc.premia (rodzaj, kwota) VALUES
('roczna', 1000),
('miesiêczna', 200),
('zadaniowa', 500),
('roczna', 1200),
('miesiêczna', 150),
('zadaniowa', 400),
('miesiêczna', 250),
('zadaniowa', 300),
('roczna', 800),
('miesiêczna', 100);
GO

-- Wynagrodzenie
INSERT INTO ksiegowosc.wynagrodzenie (data, id_pracownika, id_godziny, id_pensji, id_premii) VALUES
('2025-09-30', 1, 1, 1, 1),
('2025-09-30', 2, 2, 2, 2),
('2025-09-30', 3, 3, 3, NULL),
('2025-09-30', 4, 4, 4, 4),
('2025-09-30', 5, 5, 5, 5),
('2025-09-30', 6, 6, 6, NULL),
('2025-09-30', 7, 7, 7, 7),
('2025-09-30', 8, 8, 8, 8),
('2025-09-30', 9, 9, 9, NULL),
('2025-09-30', 10, 10, 10, 10);
GO
*/

--5. Wykonaj nastêpuj¹ce zapytania:
--a) Wyœwietl tylko id pracownika oraz jego nazwisko. 
--SELECT id_pracownika, nazwisko FROM ksiegowosc.pracownicy;

--b) Wyœwietl id pracowników, których p³aca jest wiêksza ni¿ 1000. 
/*
SELECT w.id_pracownika FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
WHERE pe.kwota > 1000;
*/

--c) Wyœwietl id pracowników nieposiadaj¹cych premii, których p³aca jest wiêksza ni¿ 2000. 
/*
SELECT id_pracownika FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
WHERE w.id_premii IS NULL AND pe.kwota >2000;
*/

--d) Wyœwietl pracowników, których pierwsza litera imienia zaczyna siê na literê ‘J’. 
/*
SELECT * FROM ksiegowosc.pracownicy 
WHERE imie LIKE 'J%';
*/
--e) Wyœwietl pracowników, których nazwisko zawiera literê ‘n’ oraz imiê koñczy siê na literê ‘a’. 
/*
SELECT * FROM ksiegowosc.pracownicy 
WHERE nazwisko LIKE '%n%' AND imie LIKE '%a';
*/
--f) Wyœwietl imiê i nazwisko pracowników oraz liczbê ich nadgodzin, przyjmuj¹c, i¿ standardowy czas pracy to 160 h miesiêcznie. 
/*
SELECT p.imie, p.nazwisko, (g.liczba_godzin - 160) AS nadgodziny
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.godziny g ON p.id_pracownika = g.id_pracownika;
*/
--g) Wyœwietl imiê i nazwisko pracowników, których pensja zawiera siê w przedziale 1500 – 3000 PLN. 
/*
SELECT p.imie, p.nazwisko, pe.kwota
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON p.id_pracownika = w.id_pracownika
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
WHERE pe.kwota BETWEEN 1500 AND 3000;
*/
--h) Wyœwietl imiê i nazwisko pracowników, którzy pracowali w nadgodzinach i nie otrzymali premii. 
/*
SELECT p.imie, p.nazwisko FROM ksiegowosc.pracownicy AS p
JOIN ksiegowosc.godziny g ON p.id_pracownika = g.id_pracownika
JOIN ksiegowosc.wynagrodzenie w ON p.id_pracownika = w.id_pracownika
WHERE g.liczba_godzin > 160 AND w.id_premii IS NULL;
*/
--i) Uszereguj pracowników wed³ug pensji. 
/*
SELECT p.imie, p.nazwisko, pe.kwota AS pensja
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON p.id_pracownika = w.id_pracownika
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
ORDER BY pe.kwota;
*/
--j) Uszereguj pracowników wed³ug pensji i premii malej¹co. 
/*
SELECT p.imie, p.nazwisko, pe.kwota AS pensja, ISNULL(pr.kwota, 0) AS premia
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON p.id_pracownika = w.id_pracownika
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
LEFT JOIN ksiegowosc.premia pr ON w.id_premii = pr.id_premii
ORDER BY pe.kwota DESC, pr.kwota DESC;  
*/
--k) Zlicz i pogrupuj pracowników wed³ug pola ‘stanowisko’. 
/*
SELECT pe.stanowisko, COUNT(*) AS liczba_pracownikow
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
GROUP BY pe.stanowisko;
*/
--l) Policz œredni¹, minimaln¹ i maksymaln¹ p³acê dla stanowiska ‘kierownik’ (je¿eli takiego nie masz, to przyjmij dowolne inne). 
/*
SELECT pe.stanowisko, 
	AVG(pe.kwota) AS srednia, 
	MIN(pe.kwota) AS minimalna, 
	MAX(pe.kwota) AS maksymalna
FROM ksiegowosc.pensja pe
WHERE pe.stanowisko = 'kierownik'
GROUP BY pe.stanowisko;
*/
--m) Policz sumê wszystkich wynagrodzeñ. 
/*
SELECT SUM(pe.kwota + ISNULL(pr.kwota,0)) AS suma_wynagrodzen FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
LEFT JOIN ksiegowosc.premia pr ON w.id_premii = pr.id_premii;
*/
--f) Policz sumê wynagrodzeñ w ramach danego stanowiska. 
/*
SELECT pe.stanowisko, SUM(pe.kwota + ISNULL(pr.kwota,0)) AS suma_wynagrodzen
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
LEFT JOIN ksiegowosc.premia pr ON w.id_premii = pr.id_premii
GROUP BY pe.stanowisko;
*/
--g) Wyznacz liczbê premii przyznanych dla pracowników danego stanowiska. 
/*
SELECT pe.stanowisko, COUNT(pr.id_premii) AS liczba_premii
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON w.id_pensji = pe.id_pensji
LEFT JOIN ksiegowosc.premia pr ON w.id_premii = pr.id_premii
GROUP BY pe.stanowisko;
*/
--h) Usuñ wszystkich pracowników maj¹cych pensjê mniejsz¹ ni¿ 1200 z³. (Zmieni³am na 2000, bo nie mia³am tutaj ¿adnej wartoœci)
/*
DELETE w
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja p ON w.id_pensji = p.id_pensji
WHERE p.kwota < 2000;

DELETE FROM ksiegowosc.pracownicy
WHERE id_pracownika NOT IN (SELECT id_pracownika FROM ksiegowosc.wynagrodzenie);
-- Dla sprawdzenia
SELECT * FROM ksiegowosc.wynagrodzenie
SELECT * FROM ksiegowosc.godziny
SELECT * FROM ksiegowosc.pensja
SELECT * FROM ksiegowosc.pracownicy
SELECT * FROM ksiegowosc.premia
*/