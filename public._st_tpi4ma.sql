-- FUNCTION: public._st_tpi4ma(double precision[], integer[], text[])

-- DROP FUNCTION IF EXISTS public._st_tpi4ma(double precision[], integer[], text[]);

CREATE OR REPLACE FUNCTION public._st_tpi4ma(
	value double precision[],
	pos integer[],
	VARIADIC userargs text[] DEFAULT NULL::text[])
    RETURNS double precision
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL SAFE 
AS $BODY$
	DECLARE
		x integer;
		y integer;
		z integer;

		Z1 double precision;
		Z2 double precision;
		Z3 double precision;
		Z4 double precision;
		Z5 double precision;
		Z6 double precision;
		Z7 double precision;
		Z8 double precision;
		Z9 double precision;

		tpi double precision;
		mean double precision;
		_value double precision[][][];
		ndims int;
	BEGIN
		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		-- check that center pixel isn't NODATA
		IF _value[z][2][2] IS NULL THEN
			RETURN NULL;
		-- substitute center pixel for any neighbor pixels that are NODATA
		ELSE
			FOR y IN 1..3 LOOP
				FOR x IN 1..3 LOOP
					IF _value[z][y][x] IS NULL THEN
						_value[z][y][x] = _value[z][2][2];
					END IF;
				END LOOP;
			END LOOP;
		END IF;

		-------------------------------------------------
		--|   Z1= Z(-1,1) |  Z2= Z(0,1)	| Z3= Z(1,1)  |--
		-------------------------------------------------
		--|   Z4= Z(-1,0) |  Z5= Z(0,0) | Z6= Z(1,0)  |--
		-------------------------------------------------
		--|   Z7= Z(-1,-1)|  Z8= Z(0,-1)|  Z9= Z(1,-1)|--
		-------------------------------------------------

		Z1 := _value[z][1][1];
		Z2 := _value[z][2][1];
		Z3 := _value[z][3][1];
		Z4 := _value[z][1][2];
		Z5 := _value[z][2][2];
		Z6 := _value[z][3][2];
		Z7 := _value[z][1][3];
		Z8 := _value[z][2][3];
		Z9 := _value[z][3][3];

		mean := (Z1 + Z2 + Z3 + Z4 + Z6 + Z7 + Z8 + Z9)/8;
		tpi := Z5-mean;

		return tpi;
	END;
	
$BODY$;

ALTER FUNCTION public._st_tpi4ma(double precision[], integer[], text[])
    OWNER TO postgres;
-- Funkcja działa w pętli na poziomie pojedynczego piksela, analizując jego otoczenie (tzw. okno 3x3 piksele). 
-- W pierwszej kolejności kod zabezpiecza dane przed błędami (np. na krawędziach mapy), podstawiając wartość środkowego piksela w miejsca, gdzie brakuje danych. 
-- Następnie wykonuje wzór na wskaźnik TPI: sumuje wartości wysokości 8 sąsiadów, oblicza ich średnią, 
-- a na końcu odejmuje tę średnią od wartości piksela centralnego. 
-- Wynik tej operacji informuje nas o rzeźbie terenu: 
-- wartości dodatnie oznaczają wypukłości (grzbiety), a ujemne wklęsłości (doliny).