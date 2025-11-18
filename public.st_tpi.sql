-- FUNCTION: public.st_tpi(raster, integer, text, boolean)

-- DROP FUNCTION IF EXISTS public.st_tpi(raster, integer, text, boolean);

CREATE OR REPLACE FUNCTION public.st_tpi(
	rast raster,
	nband integer DEFAULT 1,
	pixeltype text DEFAULT '32BF'::text,
	interpolate_nodata boolean DEFAULT false)
    RETURNS raster
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL SAFE 
AS $BODY$
 SELECT public.ST_tpi($1, $2, NULL::public.raster, $3, $4) 
$BODY$;

ALTER FUNCTION public.st_tpi(raster, integer, text, boolean)
    OWNER TO postgres;
--Kod funkcji jest krótki, ponieważ nie wykonuje ona bezpośrednio żadnych obliczeń matematycznych na pikselach. 
--Zamiast tego wywołuje funkcję silnika PostGIS – ST_MapAlgebra. 
--Zadaniem st_tpi jest przygotowanie rastra wejściowego oraz wskazanie, 
--jakiej procedury należy użyć do przetwarzania każdego piksela.