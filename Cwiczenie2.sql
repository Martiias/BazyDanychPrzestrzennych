-- 1.Zainstaluj rozszerzenie PostGIS dla bazy danych PostgreSQL 
--(sprawdź, czy najnowsza dostępna wersja oprogramowania wspiera PostGIS).
-- 2.Utwórz pustą bazę danych
-- 3.Dodaj funkcjonalności PostGIS’a do bazy poleceniem CREATE EXTENSION postgis;
/*
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
SELECT postgis_full_version();
*/
-- 4.Na podstawie poniższej mapy utwórz trzy tabele: 
-- buildings (id, geometry, name), roads (id, geometry, name), poi (id, geometry, name).
/*
CREATE TABLE buildings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY(POLYGON, 0) 
);

CREATE TABLE roads (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY(LINESTRING, 0)
);

CREATE TABLE poi (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY(POINT, 0)
);
*/
-- 5. Współrzędne obiektów oraz nazwy (np. BuildingA) należy odczytać z mapki umieszczonej poniżej. 
-- Układ współrzędnych ustaw jako niezdefiniowany
/*
-- BUILDINGS
INSERT INTO buildings (name, geom) VALUES
('BuildingA', ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 0)),
('BuildingB', ST_GeomFromText('POLYGON((6 5, 6 7, 4 7, 4 5, 6 5))', 0)),
('BuildingC', ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))', 0)),
('BuildingD', ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))', 0)),
('BuildingF', ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))', 0));

-- ROADS
INSERT INTO roads (name, geom) VALUES
('RoadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0)),
('RoadY', ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)', 0));

-- POINTS
INSERT INTO poi (name, geom) VALUES
('G', ST_GeomFromText('POINT(1 3.5)', 0)),
('H', ST_GeomFromText('POINT(5.5 1.5)', 0)),
('I', ST_GeomFromText('POINT(9.5 6)', 0)),
('J', ST_GeomFromText('POINT(6.5 6)', 0)),
('K', ST_GeomFromText('POINT(6 9.5)', 0));
*/
-- 6.Na bazie przygotowanych tabel wykonaj poniższe polecenia:

-- a. Wyznacz całkowitą długość dróg w analizowanym mieście
SELECT SUM(ST_Length(geom)) AS total_length FROM roads;

-- b. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA. 
SELECT 
    ST_AsText(geom) AS wkt,
    ST_Area(geom) AS area,
    ST_Perimeter(geom) AS perimeter
FROM buildings
WHERE name = 'BuildingA';

--c.Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie
SELECT name, ST_Area(geom) AS area
FROM buildings
ORDER BY name ASC;

--d. Wypisz nazwy i obwody 2 budynków o największej powierzchni
SELECT name, ST_Perimeter(geom) AS perimeter
FROM buildings
ORDER BY ST_Area(geom) DESC
LIMIT 2;

--e. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem K. 
SELECT ST_Distance(b.geom, p.geom) AS distance
FROM buildings b, poi p
WHERE b.name = 'BuildingC' AND p.name = 'K';

--f. Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości 
--większej niż 0.5 od budynku BuildingB.
SELECT ST_Area(ST_Difference(c.geom,ST_Buffer(b.geom, 0.5))) AS area
FROM buildings AS c
JOIN buildings AS b ON b.name = 'BuildingB'
WHERE c.name = 'BuildingC';

--g. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX.
SELECT b.name
FROM buildings AS b
JOIN roads AS r ON r.name = 'RoadX'
WHERE ST_Y(ST_Centroid(b.geom)) > ST_YMax(r.geom);

--h. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych
--(4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
SELECT ST_Area(
    ST_SymDifference(
        (SELECT geom FROM buildings WHERE name = 'BuildingC'),
        ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0)
    )
) AS difference_area;
