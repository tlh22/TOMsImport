/***
Obtain the "end" lines from the bounding polygon
***/

DO $$
DECLARE 
	r1 record;
	r2 record;
	r3 record;
	check_distance double precision := 1.5;
	road_casement_distance double precision := 5.0;
	max_line_length double precision := 2.5;
	closest_pt geometry;
	bearing_to_kerbline double precision;
	diffAz double precision;
	new_start_pt geometry;
	new_end_pt geometry;
	newline geometry;
	check_angle double precision := 15.0;
	change BOOLEAN;
BEGIN

    FOR r1 IN 
		SELECT id, ogc_fid, geom, ST_StartPoint(geom) AS Medial_StartPt, ST_EndPoint(geom) AS Medial_EndPt
		FROM import_geojson."MedialAxis_LineString"
		--WHERE ogc_fid = 9877
		ORDER BY ogc_fid
	LOOP
	
	 	RAISE NOTICE '***** Considering %', r1.ogc_fid;
		
		newLine = r1.geom;
		change = FALSE;
		
		-- 1. Get the bearing from medial start pt to the nearest kerbline
		
		SELECT degrees(ST_Azimuth(r1.Medial_StartPt, y.closest_pt))
		INTO bearing_to_kerbline
		FROM 
			(SELECT ST_ClosestPoint(r.geom, r1.Medial_StartPt) AS closest_pt, ST_Distance(r.geom, r1.Medial_StartPt) AS distance
			FROM topography."road_casement" r
			WHERE ST_DWithin(r.geom, r1.Medial_StartPt, road_casement_distance)
			ORDER BY 2 ASC 
			LIMIT 1) y;
		
		RAISE NOTICE '** bearing_to_kerbline (start pt): %', bearing_to_kerbline;
		
		-- Generate line segments for the bounding polygon near start point
		
		FOR r2 IN
			SELECT path, geom, degrees(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))) AS bearing, ST_Length(y.geom) AS length
			FROM (
				SELECT (ST_DumpSegments(o.geom)).*
				FROM import_geojson."Parking_Restrictions_Outline" o
				WHERE ogc_fid = r1.ogc_fid
			) y
			WHERE ST_Length(geom) < max_line_length
			AND ST_DWithin(r1.Medial_StartPt, y.geom, check_distance)
			ORDER BY path
		LOOP
		
			-- find the difference between the two bearings
			
			diffAz = bearing_to_kerbline - r2.bearing;
			
			IF diffAz < 0.0 THEN
				diffAz = diffAz + 360.0;
			END IF;
						
			if diffAz >= 180.0 THEN
				diffAz = diffAz - 180.0;
			END IF;
			
			IF diffAz >= 90.0 THEN
				diffAz = ABS (diffAz - 180.0);
			END IF;
			
			RAISE NOTICE '--- Checking line: % % % % ...', r2.path, r2.bearing, r2.length, diffAz;
			
			IF diffAz < check_angle THEN
				RAISE NOTICE '------- Found line: % % % ...', r2.path, r2.bearing, r2.length;
				
				-- Find the nearest point on this line to the start pt
				new_start_pt = ST_ClosestPoint(r2.geom, r1.Medial_StartPt);
				IF NOT (new_start_pt = r1.Medial_StartPt) THEN
					RAISE NOTICE '------- Adding point ... %', ST_AsText(new_start_pt);
					newLine = ST_MAKELINE(new_start_pt, newline);
					change = TRUE;
				END IF;
			END IF;
			
		END LOOP;

		-- 2. Get the bearing from medial end pt to the nearest kerbline
		
		SELECT degrees(ST_Azimuth(r1.Medial_EndPt, y.closest_pt))
		INTO bearing_to_kerbline
		FROM 
			(SELECT ST_ClosestPoint(r.geom, r1.Medial_EndPt) AS closest_pt, ST_Distance(r.geom, r1.Medial_EndPt) AS distance
			FROM topography."road_casement" r
			WHERE ST_DWithin(r.geom, r1.Medial_StartPt, road_casement_distance)
			ORDER BY 2 ASC 
			LIMIT 1) y;
		
		RAISE NOTICE '*** bearing_to_kerbline (end pt): %', bearing_to_kerbline;
		
		-- Generate line segments for the bounding polygon near end point
		
		FOR r3 IN
			SELECT path, geom, degrees(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))) AS bearing, ST_Length(y.geom) AS length
			FROM (
				SELECT (ST_DumpSegments(o.geom)).*
				FROM import_geojson."Parking_Restrictions_Outline" o
				WHERE ogc_fid = r1.ogc_fid
			) y
			WHERE ST_Length(geom) < max_line_length
			AND ST_DWithin(r1.Medial_EndPt, y.geom, check_distance)
			ORDER BY path
		LOOP
		
			-- find the difference between the two bearings
			diffAz = bearing_to_kerbline - r3.bearing;
			
			IF diffAz < 0.0 THEN
				diffAz = diffAz + 360.0;
			END IF;
						
			if diffAz >= 180.0 THEN
				diffAz = diffAz - 180.0;
			END IF;
			
			IF diffAz >= 90.0 THEN
				diffAz = ABS (diffAz - 180.0);
			END IF;
			
			RAISE NOTICE '--- Checking line: % % % % ...', r3.path, r3.bearing, r3.length, diffAz;
			
			IF diffAz < check_angle THEN
			
				RAISE NOTICE '------- Found line: % % % ...', r3.path, r3.bearing, r3.length;
				
				-- Find the nearest point on this line to the end pt
				
				new_end_pt = ST_ClosestPoint(r3.geom, r1.Medial_EndPt);
				IF NOT (new_end_pt = r1.Medial_EndPt) THEN
					RAISE NOTICE '------- Adding point ... %', ST_AsText(new_end_pt);
					newLine = ST_MAKELINE(newline, new_end_pt);
					change = TRUE;
				END IF;
			END IF;
			
		END LOOP;

		-- make changes
		
		IF change = TRUE THEN
		
			UPDATE import_geojson."MedialAxis_LineString"
			SET geom = newLine
			WHERE id = r1.id;
		
		END IF;

    END LOOP;
	
END$$;