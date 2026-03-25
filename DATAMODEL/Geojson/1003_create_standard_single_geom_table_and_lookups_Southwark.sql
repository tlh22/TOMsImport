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

CREATE INDEX IF NOT EXISTS "sidx_MedialAxis_LineString_geom"
    ON import_geojson."MedialAxis_LineString" USING gist
    (geom)
    TABLESPACE pg_default;

INSERT INTO import_geojson."MedialAxis_LineString"(
	ogc_fid, "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note",
	geom)
SELECT ogc_fid, Zone_type, Zone_name, Street_name, Restriction_type_codes, Restriction_type_names, Parking_code, Bays, Entitlements, Operating_hours, Exceptions, Tariffs, Note,
	(ST_DUMP(ST_LineMerge(ST_ApproximateMedialAxis(geom)))).geom AS geom
	FROM import_geojson."Parking_Restrictions_Polygon";

-- Create table with all end/start points

DROP TABLE IF EXISTS import_geojson."MedialAxis_Ends" CASCADE;

CREATE TABLE import_geojson."MedialAxis_Ends"
(
  id SERIAL,
  fid INTEGER,
  ogc_fid INTEGER,
  geom public.geometry(Point,27700),
  CONSTRAINT "MedialAxis_Ends_pkey" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE import_geojson."MedialAxis_Ends"
  OWNER TO postgres;
GRANT ALL ON TABLE import_geojson."MedialAxis_Ends" TO postgres;

-- DROP INDEX import_geojson."sidx_MedialAxis_Ends_geom"

CREATE INDEX "sidx_MedialAxis_Ends_geom"
  ON import_geojson."MedialAxis_Ends"
  USING gist
  (geom);

INSERT INTO import_geojson."MedialAxis_Ends" (fid, ogc_fid, geom)
SELECT id, ogc_fid, ST_StartPoint(geom)
FROM import_geojson."MedialAxis_LineString"
UNION
SELECT id, ogc_fid, ST_EndPoint(geom)
FROM import_geojson."MedialAxis_LineString";

-- find all the lines that do not have matches at start/end and are < 1.5m

DELETE FROM import_geojson."MedialAxis_LineString"
WHERE id NOT IN (
SELECT m1.id
FROM import_geojson."MedialAxis_LineString" m1
WHERE (
	ST_StartPoint(m1.geom) IN (
	SELECT e.geom
	FROM import_geojson."MedialAxis_Ends" e
	WHERE e.ogc_fid = m1.ogc_fid
	AND e.fid != m1.id
	)
AND ST_EndPoint(m1.geom) IN (
	SELECT e.geom
	FROM import_geojson."MedialAxis_Ends" e
	WHERE e.ogc_fid = m1.ogc_fid
	AND e.fid != m1.id
	)
)
--and m1.ogc_fid = 16908
ORDER BY m1.ogc_fid, id
)
AND ST_Length(geom) < 1.5;

DELETE FROM import_geojson."MedialAxis_Ends"
WHERE fid NOT IN (SELECT id
				  FROM import_geojson."MedialAxis_LineString")
					  ;
					  
-- check
SELECT ogc_fid, COUNT(id)
FROM import_geojson."MedialAxis_LineString"
WHERE id NOT IN (
SELECT m1.id
FROM import_geojson."MedialAxis_LineString" m1
WHERE (
	ST_StartPoint(m1.geom) IN (
	SELECT e.geom
	FROM import_geojson."MedialAxis_Ends" e
	WHERE e.ogc_fid = m1.ogc_fid
	AND e.fid != m1.id
	)
AND ST_EndPoint(m1.geom) IN (
	SELECT e.geom
	FROM import_geojson."MedialAxis_Ends" e
	WHERE e.ogc_fid = m1.ogc_fid
	AND e.fid != m1.id
	)
))
GROUP BY ogc_fid
HAVING COUNT(id) > 2

-- keep the longest sections

/***
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
***/

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
	curr_id integer;
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
		--WHERE ogc_fid = 3245 -- 12840
		GROUP BY ogc_fid
		HAVING COUNT(*) > 1
		ORDER BY ogc_fid
	LOOP

		list_ids = r1.list_ids;
		RAISE NOTICE '*****--- Considering % (%)... %', r1.ogc_fid, r1.nr_lines, list_ids;

		-- get a starting section
		
		SELECT m.id, m.geom, ST_STARTPOINT(m.geom), ST_ENDPOINT(m.geom)
		INTO start_id, new_geom, start_pt, end_pt
		FROM import_geojson."MedialAxis_LineString" m
		WHERE m.ogc_fid = r1.ogc_fid 
		AND id NOT IN (
			SELECT m1.id
			FROM import_geojson."MedialAxis_LineString" m1
			WHERE (
				ST_StartPoint(m1.geom) IN (
				SELECT e.geom
				FROM import_geojson."MedialAxis_Ends" e
				WHERE e.ogc_fid = m1.ogc_fid
				AND e.fid != m1.id
				)
			AND ST_EndPoint(m1.geom) IN (
				SELECT e.geom
				FROM import_geojson."MedialAxis_Ends" e
				WHERE e.ogc_fid = m1.ogc_fid
				AND e.fid != m1.id
				)
			)
			AND m1.ogc_fid = m.ogc_fid
			ORDER BY m1.ogc_fid, id
			)
		LIMIT 1;
		
		list_ids = ARRAY_REMOVE(list_ids, start_id);
		
		delete_list = list_ids;
		nr_matches = 1;
		curr_id = start_id;
		
		RAISE NOTICE '*****--- Starting with % ... ', start_id;
		
		WHILE nr_matches < r1.nr_lines

		LOOP
		
			--fieldCheck = TRUE;
			
			--WHILE fieldCheck
			--LOOP
			
				-- find sections that are linked, i.e., close ...
				fieldCheck = FALSE;
				
				--RAISE NOTICE '*****--- check array (%)... ', list_ids;
				
				SELECT
				m2.id, m2.ogc_fid, m2.geom, ST_STARTPOINT(m2.geom) AS start_point, ST_ENDPOINT(m2.geom) AS end_point, TRUE AS fieldCheck
				INTO this_id, this_fid, this_geom, this_start_point, this_end_point, fieldCheck
				FROM import_geojson."MedialAxis_LineString" m2, import_geojson."MedialAxis_LineString" m1
				WHERE m2.id = ANY (list_ids)
				AND m1.id = curr_id
				AND m2.id IN (
						SELECT fid
						FROM import_geojson."MedialAxis_Ends" e
						WHERE (geom = ST_StartPoint(m1.geom)
						OR geom = ST_EndPoint(m1.geom))
						AND e.fid != m1.id
					)
					--AND m1.ogc_fid = m2.ogc_fid
					AND m1.id != m2.id
					ORDER BY m1.ogc_fid, id
					;
									
				IF fieldCheck THEN
				
					RAISE NOTICE '*****---      Found % ...', this_id;
					nr_matches = nr_matches + 1;
					list_ids = ARRAY_REMOVE(list_ids, this_id);
					curr_id = this_id;
					
					IF end_pt = this_start_point THEN
						new_geom = ST_MAKELINE(new_geom, this_geom);
						end_pt = this_end_point;
						RAISE NOTICE '*****--- end->start ...';
					ELSIF end_pt = this_end_point THEN
						new_geom = ST_MAKELINE(new_geom, ST_REVERSE(this_geom));
						end_pt = this_start_point;
						RAISE NOTICE '*****--- end->end ...';
					ELSIF start_pt = this_start_point THEN
						new_geom = ST_MAKELINE(ST_REVERSE(this_geom), new_geom);
						start_pt = this_end_point;
						RAISE NOTICE '*****--- start->start ...';
					ELSIF start_pt = this_end_point THEN
						new_geom = ST_MAKELINE(this_geom, new_geom);
						start_pt = this_start_point;
						RAISE NOTICE '*****--- start->end ...';
					ELSE
					
						RAISE EXCEPTION 'fid % - error creating link for %. Distance was % ...', r1.ogc_fid, this_id, ST_LENGTH(ST_ShortestLine(this_geom, new_geom)); 
						
					END IF;
				
				ELSE
					--nr_matches = nr_matches + 1;
					RAISE EXCEPTION '^^^ Error no match found'; 

				END IF;
				
				RAISE NOTICE '*****---      Nr Matches % ...', nr_matches;
					
			--END LOOP;
						
		END LOOP;			

		RAISE NOTICE '*****---     Updating geom for % ...', start_id;
		
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


/****
Check for short restrictions
****/

SELECT id, ogc_fid, "Restriction_type_codes", ST_Length(geom)
FROM import_geojson."MedialAxis_LineString"
WHERE ST_Length(geom) < 0.5