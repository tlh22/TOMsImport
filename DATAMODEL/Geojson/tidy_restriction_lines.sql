/***

TRY to remove kick backs

***/

-- Bays

DO $$
DECLARE 
	r1 record;
	r2 record;
	r3 record;
	diffAz_radians double precision;
	check_angle_radians double precision := 15.0*pi()/180.0;
	change BOOLEAN;
	brg_1 double precision;
	brg_radians double precision;
	pt_nr integer;
	check_distance double precision := 1.0;
BEGIN

	FOR r1 IN
		SELECT "GeometryID"
		FROM toms."Bays" o
		--WHERE "GeometryID" = 'B_0002125'
		ORDER BY "GeometryID"
	LOOP

		change = TRUE;
		RAISE NOTICE '--- Considering: %', r1."GeometryID";
		
		WHILE change = TRUE LOOP

			change = FALSE;
			
			FOR r2 IN
				SELECT "GeometryID", path, geom, degrees(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))) AS bearing, ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS bearing_radians, ST_Length(y.geom) AS length, orig_geom
				FROM (
					SELECT "GeometryID", (ST_DumpSegments(o.geom)).*, geom AS orig_geom
					FROM toms."Bays" o
					WHERE "GeometryID" = r1."GeometryID"
				) y
				ORDER BY path
			LOOP
			
				IF r2.path = ARRAY[1] THEN
					--RAISE NOTICE '--- CStart:';
					brg_radians = r2.bearing_radians;
					CONTINUE;
				END IF;
				
				-- find the difference between the two bearings
				
				diffAz_radians = ABS(brg_radians - r2.bearing_radians);

				IF diffAz_radians > 2 * pi() THEN
					diffAz_radians = diffAz_radians - 2 * pi();
				END IF;
							
				--RAISE NOTICE '--- Checking line: % % % ... %', unnest(r2.path), r2.bearing, r2.length, diffAz_radians;
				
				IF diffAz_radians > check_angle_radians AND r2.length < check_distance THEN
				
					-- Delete current start_pt
					
					pt_nr = unnest(r2.path)-1;

					--RAISE NOTICE '------- Found line: % % % ... %', pt_nr, r2.bearing, r2.length, ST_NPoints(r2.orig_geom);

					UPDATE toms."Bays"
					SET geom = ST_RemovePoint(geom, pt_nr)
					WHERE "GeometryID" = r2."GeometryID";

					change = TRUE;

					EXIT;
					
				END IF;

				brg_radians = r2.bearing_radians;
				
			END LOOP;

		END LOOP;
	
	END LOOP;
	
END$$;

-- Lines

DO $$
DECLARE 
	r1 record;
	r2 record;
	r3 record;
	diffAz_radians double precision;
	check_angle_radians double precision := 15.0*pi()/180.0;
	change BOOLEAN;
	brg_1 double precision;
	brg_radians double precision;
	pt_nr integer;
	check_distance double precision := 2.0;
BEGIN

	FOR r1 IN
		SELECT "GeometryID"
		FROM toms."Lines" o
		--WHERE "GeometryID" = 'B_0002125'
		ORDER BY "GeometryID"
	LOOP
	
		change = TRUE;
		RAISE NOTICE '--- Considering: %', r1."GeometryID";
		
		WHILE change = TRUE LOOP

			change = FALSE;
			
			FOR r2 IN
				SELECT "GeometryID", path, geom, degrees(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))) AS bearing, ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom)) AS bearing_radians, ST_Length(y.geom) AS length, orig_geom
				FROM (
					SELECT "GeometryID", (ST_DumpSegments(o.geom)).*, geom AS orig_geom
					FROM toms."Lines" o
					WHERE "GeometryID" = r1."GeometryID"
				) y
				ORDER BY path
			LOOP
			
				IF r2.path = ARRAY[1] THEN
					--RAISE NOTICE '--- CStart:';
					brg_radians = r2.bearing_radians;
					CONTINUE;
				END IF;
				
				-- find the difference between the two bearings
				
				diffAz_radians = ABS(brg_radians - r2.bearing_radians);

				IF diffAz_radians > 2 * pi() THEN
					diffAz_radians = diffAz_radians - 2 * pi();
				END IF;
							
				--RAISE NOTICE '--- Checking line: % % % ... %', unnest(r2.path), r2.bearing, r2.length, diffAz_radians;
				
				IF diffAz_radians > check_angle_radians AND r2.length < check_distance THEN
				
					-- Delete current start_pt
					
					pt_nr = unnest(r2.path)-1;

					--RAISE NOTICE '------- Found line: % % % ... %', pt_nr, r2.bearing, r2.length, ST_NPoints(r2.orig_geom);

					UPDATE toms."Lines"
					SET geom = ST_RemovePoint(geom, pt_nr)
					WHERE "GeometryID" = r2."GeometryID";

					change = TRUE;

					EXIT;
					
				END IF;

				brg_radians = r2.bearing_radians;
				
			END LOOP;

		END LOOP;
	
	END LOOP;
	
END$$;




WITH segments AS (
SELECT "GeometryID", unnest((pt).path)-1, ST_AsText(ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY "GeometryID" ORDER BY "GeometryID", (pt).path), (pt).geom)) AS geom
  FROM (SELECT "GeometryID", ST_DumpPoints(geom) AS pt FROM toms."Lines"
  WHERE "GeometryID" = 'L_0007433') as dumps
)
SELECT * FROM segments WHERE geom IS NOT NULL