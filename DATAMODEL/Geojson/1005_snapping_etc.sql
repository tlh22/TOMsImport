/***

Snapping:
0.5 for duplicate points, snap to each other and kerbline
1.5 snap to kerbline

***/


-- Check for restrictions that are not on kerbline

SELECT "GeometryID"
FROM topography."road_casement" c, import_geojson."Imported_Bays" r
WHERE ST_DWithin(r.geom, c.geom, 0.25)
AND 
(
	ST_LENGTH(ST_ShortestLine(c.geom, ST_StartPoint(r.geom))) > 0.25 OR
	ST_LENGTH(ST_ShortestLine(c.geom, ST_EndPoint(r.geom))) > 0.25
	)
ORDER BY "GeometryID"
;

-- Check Zig Zags

SELECT "GeometryID"
FROM import_geojson."Imported_Lines" r
WHERE r."Restriction_type_codes" IN ( 'ASKCL' )
ORDER BY "GeometryID";

SELECT "GeometryID"
FROM topography."road_casement" c, import_geojson."Imported_Lines" r
WHERE ST_DWithin(r.geom, c.geom, 0.25)
AND 
(
	ST_LENGTH(ST_ShortestLine(c.geom, ST_StartPoint(r.geom))) > 0.25 OR
	ST_LENGTH(ST_ShortestLine(c.geom, ST_EndPoint(r.geom))) > 0.25
	)
ORDER BY "GeometryID"
;


SELECT "GeometryID", ST_Length(geom)
FROM import_geojson."Imported_Lines" r
WHERE ST_Length(geom) < 0.5
ORDER BY "GeometryID";


-- Create a single feature from road_casement

DROP TABLE IF EXISTS topography."RoadCasement_SingleFeature";
CREATE TABLE IF NOT EXISTS topography."RoadCasement_SingleFeature"
(
  id SERIAL,
  geom public.geometry(MultiLineString,27700),
  CONSTRAINT "RoadCasement_SingleFeature_pkey" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE topography."RoadCasement_SingleFeature"
  OWNER TO postgres;
GRANT ALL ON TABLE topography."RoadCasement_SingleFeature" TO postgres;

CREATE INDEX "sidx_RoadCasement_SingleFeature_geom"
  ON topography."RoadCasement_SingleFeature"
  USING gist
  (geom);

INSERT INTO topography."RoadCasement_SingleFeature" (geom)
SELECT ST_Multi(ST_Collect(geom)) As geom
FROM topography."road_casement";


SELECT "GeometryID"
FROM topography."RoadCasement_SingleFeature" c, import_geojson."Imported_Lines" r
WHERE NOT ST_DWithin(r.geom, c.geom, 0.25)
ORDER BY "GeometryID"
;

SELECT "GeometryID"
FROM topography."RoadCasement_SingleFeature" c, import_geojson."Imported_Bays" r
WHERE NOT ST_DWithin(r.geom, c.geom, 0.25)
ORDER BY "GeometryID"
;

/***
check for restrictions that have disappeared
***/

SELECT ogc_fid
FROM import_geojson."Parking_Restrictions_Polygon"
WHERE ogc_fid NOT IN (
SELECT ogc_fid
FROM import_geojson."Imported_Bays"
UNION
SELECT ogc_fid
FROM import_geojson."Imported_Lines"
)

/***

-- OR 

SELECT r.ogc_fid
FROM import_geojson."Parking_Restrictions_Polygon" r, local_authority."SiteArea_AB" s
WHERE ST_Intersects(r.geom, s.geom)
AND r.ogc_fid NOT IN (
SELECT ogc_fid
FROM import_geojson."Imported_Bays"
UNION
SELECT ogc_fid
FROM import_geojson."Imported_Lines"
)

***/