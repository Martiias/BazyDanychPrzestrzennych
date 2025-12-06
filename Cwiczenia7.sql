-- 6. Przycięcie mapy rastrowej do granic parku
DROP TABLE IF EXISTS uk_lake_district;

CREATE TABLE uk_lake_district AS
SELECT 
    ST_Clip(r.rast, p.geom, true) AS rast
FROM 
    public.uk_250k AS r
INNER JOIN 
    public.national_parks AS p 
    ON ST_Intersects(r.rast, p.geom)
WHERE 
    -- Punkt w centrum Lake District (Ambleside)
    ST_Intersects(p.geom, ST_SetSRID(ST_Point(330000, 508000), 27700));

-- Dodanie klucza głównego i metadanych (wymagane dla QGIS)
ALTER TABLE uk_lake_district ADD COLUMN rid SERIAL PRIMARY KEY;
SELECT AddRasterConstraints('uk_lake_district'::name, 'rast'::name);


-- 10. Policz indeks NDWI oraz przytnij wyniki do granic Lake District.
DROP TABLE IF EXISTS lake_district_ndwi;

CREATE TABLE lake_district_ndwi AS
WITH 
-- Agregacja kafelków dla poszczególnych kanałów
b3_full AS (
    SELECT ST_Union(rast) AS rast FROM public.sentinel_b3
),
b8_full AS (
    SELECT ST_Union(rast) AS rast FROM public.sentinel_b8
),
-- Transformacja geometrii parku do układu współrzędnych rastra
park_geom AS (
    SELECT ST_Transform(p.geom, ST_SRID(b3.rast)) AS geom
    FROM public.national_parks p, b3_full b3
    WHERE ST_Intersects(p.geom, ST_SetSRID(ST_Point(330000, 508000), 27700))
    LIMIT 1
)
SELECT 
    ST_Clip(
        ST_MapAlgebra(
            b3.rast, 
            b8.rast,-- Obliczenie wzoru NDWI z rzutowaniem na typ float
            '([rast1]::float - [rast2]::float) / ([rast1]::float + [rast2]::float)',
            '32BF' -- Inaczej PostGIS wciśnie to do integera i utnie wszystko od 0 do 1
        ),
        p.geom,
        true
    ) AS rast
FROM 
    b3_full b3, 
    b8_full b8, 
    park_geom p;

-- Dodanie klucza głównego i metadanych (wymagane dla QGIS)
ALTER TABLE lake_district_ndwi ADD COLUMN rid SERIAL PRIMARY KEY;
SELECT AddRasterConstraints('lake_district_ndwi'::name, 'rast'::name);