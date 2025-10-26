-- 1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana
-- pomiędzy 2018 a 2019).

DROP TABLE IF EXISTS changed_buildings;

CREATE TABLE changed_buildings AS
SELECT 
	b19.gid,
    b19.polygon_id,
	b19.name,
	b19.type,
	b19.height,
    b19.geom
FROM buildings_2019 b19
LEFT JOIN buildings_2018 b18
    ON b19.polygon_id = b18.polygon_id
WHERE NOT ST_Equals(b18.geom, b19.geom);

SELECT * FROM changed_buildings;

-- 2. Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
-- wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.

DROP TABLE IF EXISTS new_poi;

-- Tworzę tabele z nowymi POI
CREATE TABLE new_poi AS
SELECT 
	p19.gid,
    p19.poi_id,
    p19.link_id,
	p19.type,
	p19.poi_name,
	p19.st_name,
	p19.lat,
	p19.lon,
    p19.geom 
FROM poi_2019 p19
LEFT JOIN poi_2018 p18
  ON p19.poi_id = p18.poi_id
WHERE p18.poi_id IS NULL;

-- Znajduję ile nowych POI jest w promieniu 500 m od budynków z 1
SELECT p.type AS category, COUNT(DISTINCT p.poi_id) AS poi_count
FROM new_poi p
JOIN changed_buildings b
  ON ST_DWithin(p.geom, b.geom, 500)
GROUP BY p.type
ORDER BY poi_count DESC;


-- 3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
-- T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini

DROP TABLE IF EXISTS streets_reprojected;
CREATE TABLE streets_reprojected AS
SELECT 
    *,
    ST_Transform(geom, 31467) AS geom_reprojected
FROM streets_2019;

-- 4.Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej

DROP TABLE IF EXISTS input_points;

CREATE TABLE input_points (
    id SERIAL PRIMARY KEY,
    geom geometry(Point, 4326) -- WGS 84
);

INSERT INTO input_points (geom)
VALUES
    (ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
    (ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));

-- 5.Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
-- DHDN.Berlin/Cassini.

ALTER TABLE input_points
ALTER COLUMN geom TYPE geometry(Point) USING geom;
UPDATE input_points
SET geom = ST_Transform(geom, 31467);

-- 6.Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
-- z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
-- reprojekcji geometrii, aby była zgodna z resztą tabel.

-- Indeks na węzłach, dzięki temu PostGIS szybko znajdzie węzły w pobliżu linii
CREATE INDEX IF NOT EXISTS streets_node_2019_gix ON streets_node_2019 USING GIST (geom);

-- Indeks na drogach przetransformowanych, dzięki temu PostGIS szybko sprawdzi, czy węzeł leży na drodze
CREATE INDEX IF NOT EXISTS streets_reprojected_gix ON streets_reprojected USING GIST (geom_reprojected);

-- Tworzę tymczasową linię z punktów
DROP TABLE IF EXISTS tmp_input_line;
CREATE TEMP TABLE tmp_input_line AS
SELECT ST_MakeLine(geom ORDER BY id) AS geom_line
FROM input_points;

-- Wybieram skrzyżowania, gdzie węzły są tylko skrzyżowaniami (?) (intersect = 'Y')
-- W promieniu 200 m od linii utworzonej z punktów
-- (?) Które faktycznie leżą na drodze z tabeli streets_reprojected

SELECT DISTINCT n.*
FROM streets_node_2019 n, tmp_input_line l
WHERE n.intersect = 'Y'
  AND ST_DWithin(ST_Transform(n.geom, 31467), l.geom_line, 200)
  AND EXISTS ( -- Sprawdzam czy skrzyżowanie jest na drodze z 3 zadania
        SELECT 1
        FROM streets_reprojected s
        WHERE ST_DWithin(ST_Transform(n.geom, 31467), s.geom_reprojected, 1)
      );

-- 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
-- w odległości 300 m od parków (LAND_USE_A).

SELECT COUNT(DISTINCT p.poi_id) AS sporting_goods_near_parks
FROM poi_2019 p
JOIN land_use_a2019 l
  ON ST_DWithin(p.geom, l.geom, 300)
WHERE p.type = 'Sporting Goods Store';

-- 8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
-- znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’

DROP TABLE IF EXISTS T2019_KAR_BRIDGES;

CREATE TABLE T2019_KAR_BRIDGES AS
SELECT
    r.gid AS railway_gid,
    w.gid AS water_gid,
    ST_Intersection(r.geom, w.geom) AS geom
FROM railways_2019 r
JOIN water_lines_2019 w
  ON ST_Intersects(r.geom, w.geom)
WHERE ST_GeometryType(ST_Intersection(r.geom, w.geom)) = 'ST_Point';

SELECT * FROM T2019_KAR_BRIDGES;
