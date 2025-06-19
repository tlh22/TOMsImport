/***
 * Populate tables

 ***/

DROP TABLE IF EXISTS import_geojson."Merged_Lines" CASCADE;

CREATE TABLE IF NOT EXISTS import_geojson."Merged_Lines"
AS 
SELECT * FROM import_geojson."Southwark_single_geom"
WHERE "Restriction_type_codes" IN ( 'DYL' , 'DYL, DYKM' , 'DYL, SYKM' , 'SYL' , 'SYL, SYKM' , 'ASKCL' );

DROP TABLE IF EXISTS import_geojson."Merged_Bays" CASCADE;

CREATE TABLE import_geojson."Merged_Bays"
AS 
SELECT * FROM import_geojson."Southwark_single_geom"
WHERE "Restriction_type_codes" NOT IN ( 'DYL' , 'DYL, DYKM' , 'DYL, SYKM' , 'SYL' , 'SYL, SYKM' , 'ASKCL' );


/***
 * Now add GeometryID, etc

 ***/

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "GeometryID" integer;

UPDATE import_geojson."Merged_Lines"
SET "GeometryID" = id;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "RestrictionTypeID" integer;
	
UPDATE import_geojson."Merged_Lines" r
SET "RestrictionTypeID" = l."BayLineTypeCode"
FROM import_geojson."RestrictionTypes_Lookup" l
WHERE l."geojson_restriction_type_name" = r."Restriction_type_names";

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "GeomShapeID" integer;
	
UPDATE import_geojson."Merged_Lines"
SET "GeomShapeID" = 10;

UPDATE import_geojson."Merged_Lines"
SET "GeomShapeID" = 12
WHERE "RestrictionTypeID" = 203;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "AzimuthToRoadCentreLine" double precision;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "NoWaitingTimeID" integer;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "NoLoadingTimeID" integer;
	
ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "CPZ" character varying(40) COLLATE pg_catalog."default";

UPDATE import_geojson."Merged_Lines"
SET "CPZ" = "Zone_name";

ALTER TABLE IF EXISTS import_geojson."Merged_Lines"
  ADD COLUMN IF NOT EXISTS "RoadName" character varying(254) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Lines"
SET "RoadName" = "Street_name";
	
--

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "GeometryID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeometryID" = id;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "RestrictionTypeID" integer;

UPDATE import_geojson."Merged_Bays" r
SET "RestrictionTypeID" = l."BayLineTypeCode"
FROM import_geojson."RestrictionTypes_Lookup" l
WHERE l."geojson_restriction_type_name" = r."Restriction_type_names";

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "GeomShapeID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeomShapeID" = 21;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "AzimuthToRoadCentreLine" double precision;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "NrBays" integer;
	
ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "TimePeriodID" integer;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "MaxStayID" integer;
	
ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "NoReturnID" integer;
	
ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "CPZ" character varying(40) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Bays"
SET "CPZ" = "Zone_name";

ALTER TABLE IF EXISTS import_geojson."Merged_Bays"
  ADD COLUMN IF NOT EXISTS "RoadName" character varying(254) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Bays"
SET "RoadName" = "Street_name";

UPDATE import_geojson."Merged_Bays"
SET "NrBays" = "Bays"
WHERE "RestrictionTypeID" NOT IN (101, 109, 114, 117, 118, 119, 120, 121, 122, 125, 126, 127, 128, 129, 131, 133, 134, 135, 140, 141, 142);

UPDATE import_geojson."Merged_Bays"
SET "NrBays" = -1
WHERE "RestrictionTypeID" IN (101, 109, 114, 117, 118, 119, 120, 121, 122, 125, 126, 127, 128, 129, 131, 133, 134, 135, 140, 141, 142);

-- populate "InUse" tables

INSERT INTO "toms_lookups"."BayTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT "RestrictionTypeID", 'LineString'
FROM import_geojson."Merged_Bays"
WHERE "RestrictionTypeID" NOT IN (
SELECT DISTINCT "Code"
FROM "toms_lookups"."BayTypesInUse");

INSERT INTO "toms_lookups"."LineTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT "RestrictionTypeID", 'LineString'
FROM import_geojson."Merged_Lines"
WHERE "RestrictionTypeID" NOT IN (
SELECT DISTINCT "Code"
FROM "toms_lookups"."LineTypesInUse");

INSERT INTO "toms_lookups"."TimePeriodsInUse" ("Code")
SELECT "TimePeriodID"
FROM (
SELECT DISTINCT "TimePeriodID"
FROM import_geojson."Merged_Bays"
WHERE "TimePeriodID" IS NOT NULL
UNION
SELECT DISTINCT "NoWaitingTimeID"
FROM import_geojson."Merged_Lines"
WHERE "NoWaitingTimeID" IS NOT NULL
UNION
SELECT DISTINCT "NoLoadingTimeID"
FROM import_geojson."Merged_Lines"
WHERE "NoLoadingTimeID" IS NOT NULL
) a
WHERE "TimePeriodID" NOT IN (
SELECT DISTINCT "Code"
FROM "toms_lookups"."TimePeriodsInUse");

-- Update views

REFRESH MATERIALIZED VIEW "toms_lookups"."BayTypesInUse_View" WITH DATA;
REFRESH MATERIALIZED VIEW "toms_lookups"."LineTypesInUse_View" WITH DATA;
REFRESH MATERIALIZED VIEW "toms_lookups"."TimePeriodsInUse_View" WITH DATA;

--

UPDATE import_geojson."Merged_Bays" As p
	SET "RestrictionTypeID"=l."BayLineTypeCode"
	FROM import_geojson."RestrictionTypes_Lookup" l
	WHERE l."geojson_restriction_type_code" = p."Restriction_type_codes";
	
UPDATE import_geojson."Merged_Lines" As p
	SET "RestrictionTypeID"=l."BayLineTypeCode"
	FROM import_geojson."RestrictionTypes_Lookup" l
	WHERE l."geojson_restriction_type_code" = p."Restriction_type_codes";

UPDATE import_geojson."Merged_Bays" As p
	SET "TimePeriodID"=l."TimePeriodCode", "MaxStayID"=l."MaxStayID", "NoReturnID"=l."NoReturnID"
	FROM import_geojson."TimePeriods_Transfer" l
	WHERE p."Operating_hours" = l.operating_hours;

UPDATE import_geojson."Merged_Lines" As p
	SET "NoWaitingTimeID"=l."TimePeriodCode", "NoLoadingTimeID"=l."NoLoadingTimeID"
	FROM import_geojson."TimePeriods_Transfer" l
	WHERE p."Operating_hours" = l.operating_hours;


