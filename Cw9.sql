DROP TABLE IF EXISTS merged_south_wales_exports;
CREATE TABLE merged_south_wales_exports (
    id SERIAL PRIMARY KEY,
    geom geometry(MULTIPOLYGON, 27700)
);

INSERT INTO merged_south_wales_exports (geom)
SELECT 
    ST_CollectionExtract(ST_MakeValid(ST_Union(ST_Buffer(geom, 0.0001))), 3)
FROM 
    "Exports"
WHERE 
    geom IS NOT NULL AND NOT ST_IsEmpty(geom);

--Do zwizualizowania w QGIS
DROP TABLE IF EXISTS merged_south_wales_wgs84;

CREATE TABLE merged_south_wales_wgs84 (
    id SERIAL PRIMARY KEY,
    geom geometry(MULTIPOLYGON, 4326) -- WGS 84
);

INSERT INTO merged_south_wales_wgs84 (geom)
SELECT 
    ST_Transform(geom, 4326) 
FROM 
    merged_south_wales_exports; 