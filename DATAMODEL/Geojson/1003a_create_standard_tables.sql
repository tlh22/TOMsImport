/***
 * Populate tables

 ***/

DROP TABLE IF EXISTS import_geojson."Merged_Lines" CASCADE;

CREATE TABLE import_geojson."Merged_Lines"
AS 
SELECT * FROM import_geojson."Southwark_single_geom"
WHERE  "Restriction_type_codes" IN ( 'DYL' ,  'DYL, DYKM' ,  'DYL, SYKM' ,  'SYL' ,  'SYL, SYKM' ,  'ASKCL' );

DROP TABLE IF EXISTS import_geojson."Merged_Bays" CASCADE;

CREATE TABLE import_geojson."Merged_Bays"
AS 
SELECT * FROM import_geojson."Southwark_single_geom"
WHERE  "Restriction_type_codes" NOT IN ( 'DYL' ,  'DYL, DYKM' ,  'DYL, SYKM' ,  'SYL' ,  'SYL, SYKM' ,  'ASKCL' );


/***
 * Now add GeometryID, etc

 ***/

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Lines"
SET "GeometryID" = id;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "RestrictionTypeID" integer;
	
UPDATE import_geojson."Merged_Lines" r
SET "RestrictionTypeID" = l."BayLineTypeCode"
FROM import_geojson."RestrictionTypes_Lookup" l
WHERE l."geojson_restriction_type_name" = r."Restriction_type_names";

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeomShapeID" integer;
	
UPDATE import_geojson."Merged_Lines"
SET "GeomShapeID" = 10;

UPDATE import_geojson."Merged_Lines"
SET "GeomShapeID" = 12
WHERE "RestrictionTypeID" = 203;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "AzimuthToRoadCentreLine" double precision;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "NoWaitingTimeID" integer;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "NoLoadingTimeID" integer;
	
ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "CPZ" character varying(40) COLLATE pg_catalog."default";

UPDATE import_geojson."Merged_Lines"
SET "CPZ" = "Zone_name";

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "RoadName" character varying(254) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Lines"
SET "RoadName" = "Street_name";
	
--

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeometryID" = id;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "RestrictionTypeID" integer;

UPDATE import_geojson."Merged_Bays" r
SET "RestrictionTypeID" = l."BayLineTypeCode"
FROM import_geojson."RestrictionTypes_Lookup" l
WHERE l."geojson_restriction_type_name" = r."Restriction_type_names";

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "GeomShapeID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeomShapeID" = 21;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "AzimuthToRoadCentreLine" double precision;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "NrBays" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "TimePeriodID" integer;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "MaxStayID" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "NoReturnID" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "CPZ" character varying(40) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Bays"
SET "CPZ" = "Zone_name";

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "RoadName" character varying(254) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Bays"
SET "RoadName" = "Street_name";


