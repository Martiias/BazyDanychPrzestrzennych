-- ☆ Tworzenie rastrów z istniejących rastrów i interakcja z wektorami ☆

-- Przykład 1 - ST_Intersects - Przecięcie rastra z wektorem
CREATE TABLE stachura.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

-- 1. dodanie serial primary key:
alter table stachura.intersects
add column rid SERIAL PRIMARY KEY;

-- 2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON stachura.intersects
USING gist (ST_ConvexHull(rast));

-- 3. dodanie raster constraints:
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('stachura'::name, 'intersects'::name,'rast'::name);

-- Przykład 2 - ST_Clip - Obcinanie rastra na podstawie wektora.

CREATE TABLE stachura.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

-- Przykład 3 - ST_Union - Połączenie wielu kafelków w jeden raster.
CREATE TABLE stachura.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


-- ☆ Tworzenie rastrów z wektorów (rastrowanie) ☆

-- Przykład 1 - ST_AsRaster
-- Przykład pokazuje użycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej samej
-- charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.

CREATE TABLE stachura.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykład 2 - ST_Union
-- Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.

DROP TABLE stachura.porto_parishes; 

CREATE TABLE stachura.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykład 3 - ST_Tile
-- Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.
DROP TABLE stachura.porto_parishes; 

CREATE TABLE stachura.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- ☆ Konwertowanie rastrów na wektory (wektoryzowanie) ☆

-- Przykład 1 - ST_Intersection
-- Funkcja St_Intersection jest podobna do ST_Clip. ST_Clip zwraca raster, a ST_Intersection zwraca
-- zestaw par wartości geometria-pikse

CREATE TABLE stachura.intersection AS
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 2 - ST_DumpAsPolygons
-- ST_DumpAsPolygons konwertuje rastry w wektory (poligony)

CREATE TABLE stachura.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- ☆ Analiza rastrów ☆

-- Przykład 1 - ST_Band
-- Funkcja ST_Band służy do wyodrębniania pasm z rastra

CREATE TABLE stachura.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- Przykład 2 - ST_Clip
-- ST_Clip może być użyty do wycięcia rastra z innego rastra. Poniższy przykład wycina jedną parafię z
-- tabeli vectors.porto_parishes. Wynik będzie potrzebny do wykonania kolejnych przykładów.

CREATE TABLE stachura.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 3 - ST_Slope
-- Poniższy przykład użycia funkcji ST_Slope wygeneruje nachylenie przy użyciu poprzednio
--wygenerowanej tabeli (wzniesienie).

CREATE TABLE stachura.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM stachura.paranhos_dem AS a;

-- Przykład 4 - ST_Reclass
-- Aby zreklasyfikować raster należy użyć funkcji ST_Reclass.

CREATE TABLE stachura.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM stachura.paranhos_slope AS a;

-- Przykład 5 - ST_SummaryStats
-- Aby obliczyć statystyki rastra można użyć funkcji ST_SummaryStats. Poniższy przykład wygeneruje
-- statystyki dla kafelka.

SELECT st_summarystats(a.rast) AS stats
FROM stachura.paranhos_dem AS a;

-- Przykład 6 - ST_SummaryStats oraz Union
-- Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM stachura.paranhos_dem AS a;

-- Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM stachura.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
-- Aby wyświetlić statystykę dla każdego poligonu "parish" można użyć polecenia GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 9 - ST_Value
-- Funkcja ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów. Poniższy
-- przykład wyodrębnia punkty znajdujące się w tabeli vectors.places.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- ☆ Topographic Position Index (TPI) ☆
-- Przykład 10 - ST_TPI - Funkcja ST_Value pozwala na utworzenie mapy TPI z DEM wysokości.
create table stachura.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

-- Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON stachura.tpi30
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów:
SELECT AddRasterConstraints('stachura'::name,'tpi30'::name,'rast'::name);

-- ☆ ZADANIE DO SAMODZIELNEGO WYKONANIA ☆
CREATE TABLE stachura.tpi30_porto AS
SELECT ST_TPI(a.rast, 1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_porto_rast_gist ON stachura.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('stachura'::name, 'tpi30_porto'::name, 'rast'::name);

-- ☆Algebra map☆

-- Poniższe przykłady pokazują jak stosując obie techniki utworzyć wartości NDVI na podstawie obrazu Landsat8.
-- Wzór na NDVI: NDVI=(NIR-Red)/(NIR+Red)

-- Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE stachura.porto_ndvi AS
	WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] +
		[rast1.val])::float','32BF'
	) AS rast
FROM r;

-- Poniższe zapytanie utworzy indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON stachura.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów:
SELECT AddRasterConstraints('stachura'::name,
'porto_ndvi'::name,'rast'::name);

-- Przykład 2 – Funkcja zwrotna
-- W pierwszym kroku należy utworzyć funkcję, które będzie wywołana później:

create or replace function stachura.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

-- W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE stachura.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'stachura.ndvi(double precision[],
	integer[],text[])'::regprocedure, --> This is the function!
	'32BF'::text
) AS rast
FROM r;

-- Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON stachura.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--- Dodanie constraintów:
SELECT AddRasterConstraints('stachura'::name,'porto_ndvi2'::name,'rast'::name);

-- Przykład 3 - Funkcje TPI (osobne pliki)
--Schemat public zawiera dwie funkcje TPI:
--• public._st_tpi4ma - funkcja używana w algebrze map
--• public.st_tpi - funkcja, która wywołuje poprzednią funkcję. Istnieją dwie funkcje st_tpi, które
--różnią się liczbą dozwolonych wejść lecz obie te funkcje wykonują tę samą akcję.

-- ☆Eksport danych☆
-- Przykład 0 - Użycie QGIS
-- Przykład 1 - ST_AsTiff - tworzy dane wyjściowe jako binarną reprezentację pliku tiff
SELECT ST_AsTiff(ST_Union(rast))
FROM stachura.porto_ndvi;

-- Przykład 2 - ST_AsGDALRaster - nie zapisuje danych wyjściowych bezpośrednio na
-- dysku, natomiast dane wyjściowe są reprezentacją binarną dowolnego formatu GDAL.
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
FROM stachura.porto_ndvi;
-- SELECT ST_GDALDrivers(); -- Aby wyświetlić listę formatów obsługiwanych przez bibliotekę

--Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
 ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
 ) AS loid
FROM stachura.porto_ndvi;

SELECT lo_export(loid, 'C:\SEMESTR 5\Bazy Danych Przestrzennych\Cwiczenia6\myraster.tiff') --> Save the file in a placewhere the user postgres have access. In windows a flash drive usualy worksfine.
 FROM tmp_out;
 
SELECT lo_unlink(loid)
 FROM tmp_out; --> Delete the large object.

-- Przykład 4 - Użycie Gdal
-- Gdal obsługuje rastry z PostGISa. Polecenie gdal_translate eksportuje raster do dowolnego 
-- formatu obsługiwanego przez GDAL. 
