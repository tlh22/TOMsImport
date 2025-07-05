/***
 * Change to single geometry with standard name
 *
 ***/
 
ALTER TABLE IF EXISTS import_geojson."bermondsey parking restrictions" RENAME TO "Parking_Restrictions_Polygon";  -- *** Will need to change name of table

--
DROP TABLE IF EXISTS import_geojson."Parking_Restrictions_Outline" CASCADE;

CREATE TABLE IF NOT EXISTS import_geojson."Parking_Restrictions_Outline"
(
    id SERIAL,
	ogc_fid integer,
    geom geometry(MultiLineString,27700)
);

DROP INDEX IF EXISTS Parking_Restrictions_Outline_geom_idx;

CREATE INDEX IF NOT EXISTS Parking_Restrictions_Outline_geom_idx
  ON import_geojson."Parking_Restrictions_Outline"
  USING GIST (geom);
  
INSERT INTO import_geojson."Parking_Restrictions_Outline" (ogc_fid, geom)
SELECT ogc_fid, ST_Collect(ST_ExteriorRing(geom)) AS geom
FROM (SELECT ogc_fid, (ST_Dump(wkb_geometry)).geom As geom
	  FROM import_geojson."Parking_Restrictions_Polygon") As a
GROUP BY ogc_fid;

DELETE FROM import_geojson."Parking_Restrictions_Outline"
WHERE geom IS NULL;

--
CREATE EXTENSION postgis_sfcgal;

DROP TABLE IF EXISTS import_geojson."MedialAxis_LineString" CASCADE;

CREATE TABLE IF NOT EXISTS import_geojson."MedialAxis_LineString"
(
    id SERIAL,
	ogc_fid integer,
    geom geometry(LineString,27700),
    "Zone_type" character varying COLLATE pg_catalog."default",
    "Zone_name" character varying COLLATE pg_catalog."default",
    "Street_name" character varying COLLATE pg_catalog."default",
    "Restriction_type_codes" character varying COLLATE pg_catalog."default",
    "Restriction_type_names" character varying COLLATE pg_catalog."default",
    "Parking_code" character varying COLLATE pg_catalog."default",
    "Bays" integer,
    "Entitlements" character varying COLLATE pg_catalog."default",
    "Operating_hours" character varying COLLATE pg_catalog."default",
    "Exceptions" character varying COLLATE pg_catalog."default",
    "Tariffs" character varying COLLATE pg_catalog."default",
    "Note" character varying COLLATE pg_catalog."default",
	CONSTRAINT "MedialAxis_LineString_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

INSERT INTO import_geojson."MedialAxis_LineString"(
	ogc_fid, "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note",
	geom)
SELECT ogc_fid, Zone_type, Zone_name, Street_name, Restriction_type_codes, Restriction_type_names, Parking_code, Bays, Entitlements, Operating_hours, Exceptions, Tariffs, Note,
	(ST_DUMP(ST_LineMerge(ST_ApproximateMedialAxis(wkb_geometry)))).geom AS geom
	FROM import_geojson."Parking_Restrictions_Polygon";

-- keep the longest sections

DELETE FROM import_geojson."MedialAxis_LineString"
WHERE id NOT IN (
SELECT t.id
FROM import_geojson."MedialAxis_LineString" t,  
(SELECT ogc_fid, MAX(ST_LENGTH(geom)) AS max_Length
FROM import_geojson."MedialAxis_LineString"
GROUP BY ogc_fid) g
WHERE t.ogc_fid = g.ogc_fid
AND (ST_LENGTH(t.geom) = max_Length
OR ST_LENGTH(t.geom) > 1.5));

-- Now join any lines that are part of the same feature

DO $$
DECLARE 
	r1 record;
	r2 record;
	new_geom geometry;
	nr_matches integer;
	start_pt geometry;
	end_pt geometry;
	fieldCheck boolean := true;
	list_ids integer [];
	delete_list integer [];
	this_id integer;
	this_fid integer;
	this_geom geometry;
	this_start_point geometry;
	this_end_point geometry;
	start_id integer;
	check_distance float := 0.05;
	distance_end_start float;
	distance_start_end float;
	distance_end_end float;
	distance_start_start float;
	distance_array float [];
	array_counter integer;
	array_pos integer;
	extra_geom geometry;
	start_fid integer;
	shortest_distance float;
	curr_distance float;
BEGIN

    FOR r1 IN 
		SELECT ogc_fid, array_agg(id) AS list_ids, COUNT(*) AS nr_lines
		FROM import_geojson."MedialAxis_LineString"
		GROUP BY ogc_fid
		HAVING COUNT(*) > 1
		ORDER BY ogc_fid
	LOOP

		list_ids = r1.list_ids;
		RAISE NOTICE '*****--- Considering % (%)... %', r1.ogc_fid, r1.nr_lines, list_ids;

		-- get a starting section
		
		SELECT DISTINCT ON (m1.ogc_fid) 
		m1.id, m1.ogc_fid, m1.geom, ST_STARTPOINT(m1.geom) AS start_pt, ST_ENDPOINT(m1.geom) AS end_pt
		INTO start_id, start_fid, new_geom, start_pt, end_pt
		FROM import_geojson."MedialAxis_LineString" m1
		WHERE m1.id = ANY (list_ids)
		ORDER BY m1.ogc_fid ASC, m1.id;
		
		list_ids = ARRAY_REMOVE(list_ids, start_id);
		delete_list = list_ids;
		nr_matches = 1;
		
		--RAISE NOTICE '*****--- Considering % (%)... %', r1.ogc_fid, r1.nr_lines, list_ids;
		
		WHILE nr_matches < r1.nr_lines

		LOOP
		
			fieldCheck = TRUE;
			
			WHILE fieldCheck
			LOOP
			
				-- find sections that are linked, i.e., close ...
				fieldCheck = FALSE;
				
				--RAISE NOTICE '*****--- check array (%)... ', list_ids;
				
				SELECT
				m2.id, m2.ogc_fid, m2.geom, ST_STARTPOINT(m2.geom) AS start_point, ST_ENDPOINT(m2.geom) AS end_point, TRUE AS fieldCheck
				INTO this_id, this_fid, this_geom, this_start_point, this_end_point, fieldCheck
				FROM import_geojson."MedialAxis_LineString" m2
				WHERE m2.id = ANY (list_ids)
				AND (
				ST_DWITHIN(end_pt, ST_STARTPOINT(m2.geom), check_distance) 
				OR ST_DWITHIN(end_pt, ST_ENDPOINT(m2.geom), check_distance)
				OR ST_DWITHIN(start_pt, ST_STARTPOINT(m2.geom), check_distance)
                OR ST_DWITHIN(start_pt, ST_ENDPOINT(m2.geom), check_distance)				
				)
				ORDER BY m2.id ASC
				LIMIT 1;
			
				IF fieldCheck THEN
				
					--RAISE NOTICE '*****---      Found % ...', this_id;
					nr_matches = nr_matches + 1;
					list_ids = ARRAY_REMOVE(list_ids, this_id);
					
					IF ST_DWITHIN(end_pt, this_start_point, check_distance) THEN
						new_geom = ST_MAKELINE(new_geom, this_geom);
						end_pt = this_end_point;
					ELSIF ST_DWITHIN(end_pt, this_end_point, check_distance) THEN
						new_geom = ST_MAKELINE(new_geom, ST_REVERSE(this_geom));
						end_pt = this_start_point;
					ELSIF ST_DWITHIN(start_pt, this_start_point, check_distance) THEN
						new_geom = ST_MAKELINE(ST_REVERSE(this_geom), new_geom);
						start_pt = this_end_point;
					ELSIF ST_DWITHIN(start_pt, this_end_point, check_distance) THEN
						new_geom = ST_MAKELINE(this_geom, new_geom);
						end_pt = this_start_point;
					ELSE
					
						RAISE EXCEPTION 'fid % - error creating link for %. Distance was % ...', r1.ogc_fid, this_id, ST_LENGTH(ST_ShortestLine(this_geom, new_geom)); 
						
					END IF;
					
					--nr_matches = nr_matches + 1;

				END IF;
				
				RAISE NOTICE '*****---      Nr Matches % ...', nr_matches;
					
			END LOOP;
			
			IF nr_matches < r1.nr_lines THEN
			
				-- There are still sections to add, but they are separated
		
				--RAISE NOTICE 'Not all lines matched for % - % vs %', r1.ogc_fid, nr_matches, r1.nr_lines; 
				
				-- Find the closest section that has not been used ...

				SELECT
				m2.id, m2.ogc_fid, m2.geom, ST_STARTPOINT(m2.geom) AS start_point, ST_ENDPOINT(m2.geom) AS end_point, ST_LENGTH(ST_ShortestLine(m2.geom, new_geom))
				INTO this_id, this_fid, this_geom, this_start_point, this_end_point, shortest_distance
				FROM import_geojson."MedialAxis_LineString" m2
				WHERE m2.id = ANY (list_ids)
				ORDER BY ST_LENGTH(ST_ShortestLine(m2.geom, new_geom)) ASC
				LIMIT 1;

				RAISE NOTICE '*****---      Found % ...', this_id;
						
				nr_matches = nr_matches + 1;
				list_ids = ARRAY_REMOVE(list_ids, this_id);
					
				distance_end_start = ST_DISTANCE(end_pt, this_start_point);
				distance_start_end = ST_DISTANCE(start_pt, this_end_point);
				distance_end_end = ST_DISTANCE(end_pt, this_end_point);
				distance_start_start = ST_DISTANCE(start_pt, this_start_point);
				
				distance_array = ARRAY[distance_end_start, distance_start_end, distance_end_end, distance_start_start];
				
				array_counter = 2;
				array_pos = 1;
				shortest_distance = distance_array[1];
				
				WHILE array_counter <= 4 
				LOOP 

					curr_distance = distance_array[array_counter];
				
					IF curr_distance < shortest_distance THEN
						array_pos = array_counter;
						shortest_distance = curr_distance;
					END IF;
					
					--RAISE NOTICE '*****---      Checking dist array  % | % .. % | %', curr_distance, shortest_distance, array_pos, array_counter;
										
					array_counter = array_counter + 1;

				END LOOP;
				
				--RAISE NOTICE '*****---      Choosing dist array  % ... %', array_pos, distance_array;
				
				IF array_pos = 1 THEN
					extra_geom = ST_MAKELINE(end_pt, this_start_point);
					new_geom = ST_MAKELINE(ARRAY[new_geom, extra_geom, this_geom]);
					end_pt = this_end_point;
				ELSIF array_pos = 2 THEN
					extra_geom = ST_MAKELINE(this_end_point, start_pt);
					new_geom = ST_MAKELINE(ARRAY[this_geom, extra_geom, new_geom]);
					start_pt = this_start_point;
				ELSIF array_pos = 3 THEN
					extra_geom = ST_MAKELINE(end_pt, this_end_point);
					new_geom = ST_MAKELINE(ARRAY[new_geom, extra_geom, ST_REVERSE(this_geom)]);
					end_pt = this_start_point;
				ELSIF array_pos = 4 THEN
					extra_geom = ST_MAKELINE(this_start_point, start_pt);
					new_geom = ST_MAKELINE(ARRAY[ST_REVERSE(this_geom), extra_geom, new_geom]);
					start_pt = this_end_point;
				ELSE
				
					RAISE EXCEPTION 'fid % - error creating link for %. Distance was % ...', r1.ogc_fid, this_id, ST_LENGTH(ST_ShortestLine(this_geom, new_geom)); 

				END IF;
			
			END IF;	
			
		END LOOP;			
		
		UPDATE import_geojson."MedialAxis_LineString"
		SET geom = new_geom
		WHERE id = start_id;
		
		-- Delete any lines no longer required
		
		RAISE NOTICE '------- Deleting ids % ...', delete_list;
		
		DELETE FROM import_geojson."MedialAxis_LineString"
		WHERE id = ANY (delete_list);

    END LOOP;
	
END$$;

-- Now extend the new lines

DO $$
DECLARE 
	r record;
	A geometry;
	B geometry;
	azimuth double precision;
	length double precision;
	newlength double precision;
	newpoint geometry;
	newpoint2 geometry;
	newLine geometry;
	newLine2 geometry;
	outline geometry;
	restriction_code VARCHAR(250);
BEGIN
    FOR r IN SELECT id, ogc_fid, "Restriction_type_codes", geom FROM import_geojson."MedialAxis_LineString"
    LOOP

		SELECT geom 
		INTO outline
		FROM import_geojson."Parking_Restrictions_Outline"
		WHERE ogc_fid = r.ogc_fid;
		
		--RAISE NOTICE '*****--- Outline (%) %', r.ogc_fid, ST_AsText(outline);
		
		-- https://gis.stackexchange.com/questions/33055/extrapolating-a-line-in-postgis
		-- get the points A and B given a line L
		A := ST_STARTPOINT(r.geom);
		B := ST_PointN(r.geom, 2);

		-- get the bearing from point B --> A
		azimuth := ST_AZIMUTH(B,A);

		IF r."Restriction_type_codes" IN ( 'DYL' , 'DYL, DYKM' , 'DYL, SYKM' , 'SYL' , 'SYL, SYKM' , 'ASKCL' ) THEN
			newlength := 0.25;
		ELSE
			newlength := 1.0; 
		END IF;
		
		-- get the length of the line A --> B
		--length := ST_DISTANCE(A,B);
		newlength := 0.25;   -- increase the line length by 0.5m

		-- create a new point 0.5 away from A as B is from A
		newpoint := ST_TRANSLATE(A, sin(azimuth) * newlength, cos(azimuth) * newlength);
		--newpoint2 := ST_SNAP(newpoint, outline, 1.0);
		
		newLine = ST_MAKELINE(newpoint, r.geom);
		
		A := ST_ENDPOINT(r.geom);
		B := ST_PointN(r.geom, -2);
		-- get the bearing from point A --> B
		azimuth := ST_AZIMUTH(B,A);

		-- create a new point 0.5 away from A as B is from A
		newpoint := ST_TRANSLATE(A, sin(azimuth) * newlength, cos(azimuth) * newlength);
		--newpoint2 := ST_SNAP(newpoint, outline, 0.5);
		
		newLine2 = ST_MAKELINE(newLine, newpoint);
				
		UPDATE import_geojson."MedialAxis_LineString"
		SET geom = newLine2
		WHERE id = r.id;


    END LOOP;
END$$;

/***

set up lookup tables

***/

-- DROP TABLE IF EXISTS import_geojson."RestrictionTypes_Lookup";

CREATE TABLE IF NOT EXISTS import_geojson."RestrictionTypes_Lookup"
(
    id SERIAL,
    geojson_restriction_type_code character varying(50) COLLATE pg_catalog."default",
    geojson_restriction_type_name character varying(50) COLLATE pg_catalog."default",
    "BayLineTypeCode" integer,
    CONSTRAINT "RestrictionTypes_Lookup_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS import_geojson."RestrictionTypes_Lookup"
    OWNER to postgres;

-- Populate

INSERT INTO import_geojson."RestrictionTypes_Lookup"(
	geojson_restriction_type_code, geojson_restriction_type_name)
SELECT DISTINCT restriction_type_codes, restriction_type_names
FROM import_geojson."Parking_Restrictions_Polygon" i
WHERE NOT EXISTS (
	SELECT 1 FROM import_geojson."RestrictionTypes_Lookup" t
	WHERE i.restriction_type_codes = t.geojson_restriction_type_code
	AND i.restriction_type_names = t.geojson_restriction_type_name)
;

UPDATE import_geojson."RestrictionTypes_Lookup" As p
	SET "BayLineTypeCode" = l."Code"
	FROM toms_lookups."BayLineTypes" l
	WHERE UPPER(p."geojson_restriction_type_name") = UPPER(l."Description");
	
-- DROP TABLE IF EXISTS import_geojson."TimePeriods_Transfer";

CREATE TABLE IF NOT EXISTS import_geojson."TimePeriods_Transfer"
(
    id SERIAL,
    operating_hours character varying COLLATE pg_catalog."default",
	exceptions character varying COLLATE pg_catalog."default",
    "TimePeriodDescription" character varying(254) COLLATE pg_catalog."default",
    "AdditionalConditionDescription" character varying(254) COLLATE pg_catalog."default",
    "TimePeriodCode" integer,
    "AdditionalConditionCode" integer,
    "MaxStayID" integer,
    "NoReturnID" integer,
    "NoLoadingTimeID" integer,
    CONSTRAINT "TimePeriods_Transfer_pkey" PRIMARY KEY (id),
	UNIQUE (operating_hours, exceptions)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS import_geojson."TimePeriods_Transfer"
    OWNER to postgres;
	
-- Populate

INSERT INTO import_geojson."TimePeriods_Transfer"(
	operating_hours, exceptions)
SELECT DISTINCT operating_hours, exceptions
FROM import_geojson."Parking_Restrictions_Polygon" i
WHERE NOT EXISTS (
	SELECT 1 FROM import_geojson."TimePeriods_Transfer" t
	WHERE i.operating_hours = t.operating_hours
	AND i.exceptions = t.exceptions);
	
/***

Now add lookup details manually ...

***/


/****
Check for short restrictions
****/

SELECT id, ogc_fid, "Restriction_type_codes", ST_Length(geom)
FROM import_geojson."MedialAxis_LineString"
WHERE ST_Length(geom) < 0.5