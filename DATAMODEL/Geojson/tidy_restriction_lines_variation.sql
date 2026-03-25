/***

TRY to remove shooting lines

***/

-- Bays

DO $$
DECLARE 
	r1 record;
	r2 record;
	r3 record;
	diffAz_radians double precision;
	check_angle_radians double precision := 15.0*pi()/180.0; -- NB difference with lines
	change BOOLEAN;
	prev_bearing_radians double precision;
	curr_bearing_radians double precision;	
	pt_nr integer;
	check_distance double precision := 2.0;
	segment_length double precision;
	prev_length double precision;
BEGIN

	FOR r1 IN
		SELECT "GeometryID"
		FROM toms."Bays" o
		--WHERE "GeometryID" = 'L_0004962'
		ORDER BY "GeometryID"
	LOOP
	
		change = TRUE;
		RAISE NOTICE '--- Considering: %', r1."GeometryID";
		
		WHILE change = TRUE LOOP

			change = FALSE;
			
			FOR r2 IN
				WITH segments AS (
				SELECT "GeometryID", unnest((pt).path)-1 AS path_nr, ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY "GeometryID" ORDER BY "GeometryID", (pt).path), (pt).geom) AS geom
				  FROM (SELECT "GeometryID", ST_DumpPoints(geom) AS pt FROM toms."Bays"
				  WHERE "GeometryID" = r1."GeometryID") as dumps
				)
				SELECT * FROM segments WHERE geom IS NOT NULL
			LOOP
			
				curr_bearing_radians = ST_Azimuth(ST_StartPoint(r2.geom), ST_EndPoint(r2.geom));
				segment_length = St_Length(r2.geom);
				
				IF r2.path_nr = 1 THEN
					--RAISE NOTICE '--- CStart:';
					prev_bearing_radians = curr_bearing_radians;
					prev_length = segment_length;
					CONTINUE;
				END IF;
				
				-- find the difference between the two bearings
				
				diffAz_radians = ABS(prev_bearing_radians - curr_bearing_radians);

				IF diffAz_radians > 2 * pi() THEN
					diffAz_radians = diffAz_radians - 2 * pi();
				END IF;
							
				--RAISE NOTICE '--- Checking line: % % % ... %', r2.path_nr, degrees(curr_bearing_radians), segment_length, diffAz_radians;
				
				IF diffAz_radians > check_angle_radians AND prev_length < check_distance THEN
				
					-- Delete current start_pt
					
					pt_nr = r2.path_nr-1;

					--RAISE NOTICE '------- Found line: % % % ...', pt_nr, degrees(curr_bearing_radians), segment_length;

					UPDATE toms."Bays"
					SET geom = ST_RemovePoint(geom, pt_nr)
					WHERE "GeometryID" = r1."GeometryID";

					change = TRUE;

					EXIT;
					
				END IF;

				prev_bearing_radians = curr_bearing_radians;
				prev_length = segment_length;
				
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
	check_angle_radians double precision := 89.0*pi()/180.0; -- NB difference with bays
	change BOOLEAN;
	prev_bearing_radians double precision;
	curr_bearing_radians double precision;	
	pt_nr integer;
	check_distance double precision := 2.0;
	segment_length double precision;
	prev_length double precision;
BEGIN

	FOR r1 IN
		SELECT "GeometryID"
		FROM toms."Lines" o
		--WHERE "GeometryID" = 'L_0004962'
		ORDER BY "GeometryID"
	LOOP
	
		change = TRUE;
		RAISE NOTICE '--- Considering: %', r1."GeometryID";
		
		WHILE change = TRUE LOOP

			change = FALSE;
			
			FOR r2 IN
				WITH segments AS (
				SELECT "GeometryID", unnest((pt).path)-1 AS path_nr, ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY "GeometryID" ORDER BY "GeometryID", (pt).path), (pt).geom) AS geom
				  FROM (SELECT "GeometryID", ST_DumpPoints(geom) AS pt FROM toms."Lines"
				  WHERE "GeometryID" = r1."GeometryID") as dumps
				)
				SELECT * FROM segments WHERE geom IS NOT NULL
			LOOP
			
				curr_bearing_radians = ST_Azimuth(ST_StartPoint(r2.geom), ST_EndPoint(r2.geom));
				segment_length = St_Length(r2.geom);
				
				IF r2.path_nr = 1 THEN
					--RAISE NOTICE '--- CStart:';
					prev_bearing_radians = curr_bearing_radians;
					prev_length = segment_length;
					CONTINUE;
				END IF;
				
				-- find the difference between the two bearings
				
				diffAz_radians = ABS(prev_bearing_radians - curr_bearing_radians);

				IF diffAz_radians > 2 * pi() THEN
					diffAz_radians = diffAz_radians - 2 * pi();
				END IF;
							
				--RAISE NOTICE '--- Checking line: % % % ... %', r2.path_nr, degrees(curr_bearing_radians), segment_length, diffAz_radians;
				
				IF diffAz_radians > check_angle_radians AND prev_length < check_distance THEN
				
					-- Delete current start_pt
					
					pt_nr = r2.path_nr-1;

					--RAISE NOTICE '------- Found line: % % % ...', pt_nr, degrees(curr_bearing_radians), segment_length;

					UPDATE toms."Lines"
					SET geom = ST_RemovePoint(geom, pt_nr)
					WHERE "GeometryID" = r1."GeometryID";

					change = TRUE;

					EXIT;
					
				END IF;

				prev_bearing_radians = curr_bearing_radians;
				prev_length = segment_length;
				
			END LOOP;

		END LOOP;
	
	END LOOP;
	
END$$;

