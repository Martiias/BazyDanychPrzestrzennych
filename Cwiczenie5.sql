-- 1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej.
--Układ odniesienia ustal jako niezdefiniowany

--CREATE EXTENSION postgis;

DROP TABLE IF EXISTS obiekty;
CREATE TABLE obiekty (
    id SERIAL PRIMARY KEY,
    nazwa TEXT,
    geom GEOMETRY
);

-- a. Falista krzywa (COMPOUNDCURVE) z SRID=0
INSERT INTO obiekty (nazwa, geom)
VALUES 
    ('obiekt1', ST_SetSRID(
        ST_GeomFromText('COMPOUNDCURVE(
            (0 1, 1 1), 
            CIRCULARSTRING(1 1, 2 0, 3 1), 
            CIRCULARSTRING(3 1, 4 2, 5 1), 
            (5 1, 6 1)
        )'), 
        0
    ));
-- b. Serduszko z kołem 
INSERT INTO obiekty (nazwa, geom)
VALUES
    ('obiekt2', ST_SetSRID(
        ST_GeomFromText('CURVEPOLYGON(
            COMPOUNDCURVE(
                (10 6, 14 6), 
                CIRCULARSTRING(14 6, 16 4, 14 2), 
                CIRCULARSTRING(14 2, 12 0, 10 2), 
                (10 2, 10 6)
            ),
            CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2)
        )'),
        0
    ));
-- c. 
INSERT INTO obiekty (nazwa, geom)
VALUES
    ('obiekt3', ST_SetSRID(
        ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))'),
        0
    ));

-- d.
INSERT INTO obiekty (nazwa, geom)
VALUES
    ('obiekt4', ST_SetSRID(
        ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'),
        0
    ));
	
-- e. Punkt 3D
INSERT INTO obiekty (nazwa, geom)
VALUES
    ('obiekt5', ST_SetSRID(
        ST_GeomFromText('MULTIPOINT Z (30 30 59, 38 32 234)'),
        0
    ));

-- f.
INSERT INTO obiekty (nazwa, geom)
VALUES
    ('obiekt6', ST_SetSRID(
        ST_GeomFromText('GEOMETRYCOLLECTION(
            LINESTRING(1 1, 3 2),
            POINT(4 2)
        )'),
        0
    ));

-- Sprawdzenie wyników
SELECT ST_AsText(geom)
FROM obiekty
WHERE nazwa = 'obiekt6';

-- 2. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół
-- najkrótszej linii łączącej obiekt 3 i 4.

SELECT
    ST_Area(
        ST_Buffer(
            ST_ShortestLine(
                (SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'), -- 1. Geometria Obiektu 3
                (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')  -- 1. Geometria Obiektu 4
            ),
            5
        )
    ) AS pole_powierzchni_bufora_zad2;

-- 3. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to
-- zadanie? Zapewnij te warunki.

-- Warunek: Geometria wejściowa musi być zamknięta, czyli pierwszy i ostatni wierzchołek muszą być identyczne

-- Zamknięcie linii obiektu 4
UPDATE obiekty
SET geom = ST_SetSRID(
    ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20)'),
    0
)
WHERE nazwa = 'obiekt4';

-- Zamiana obiektu 4 na poligon
UPDATE obiekty
SET geom = ST_MakePolygon(geom)
WHERE nazwa = 'obiekt4';

-- 4. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty (nazwa, geom)
SELECT
    'obiekt7',
    ST_Collect(obiekt3.geom, obiekt4.geom)
FROM
    obiekty AS obiekt3,
    obiekty AS obiekt4
WHERE
    obiekt3.nazwa = 'obiekt3'
    AND obiekt4.nazwa = 'obiekt4';

-- 5. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone
-- wokół obiektów nie zawierających łuków.

SELECT
    SUM(ST_Area(
        ST_Buffer(geom, 5)
    )) AS sumaryczne_pole_buforow_zad5
FROM
    obiekty
WHERE
    ST_HasArc(geom) = FALSE;