/***
 * Now add GeometryID, etc

 ***/

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Lines"
SET "GeometryID" = id;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "RestrictionTypeID" integer;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeomShapeID" integer;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "AzimuthToRoadCentreLine" double precision;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "NoWaitingTimeID" integer;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "CPZ" character varying(40) COLLATE pg_catalog."default";

UPDATE import_geojson."Merged_Lines"
SET "CPZ" = "Zone_name";

--

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeometryID" = id;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "RestrictionTypeID" integer;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "GeomShapeID" integer;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "AzimuthToRoadCentreLine" double precision;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "TimePeriodID" integer;

ALTER TABLE import_geojson."Merged_Bays"
<<<<<<< Updated upstream:DATAMODEL/Geojson/1003_add_required_attributes.sql
    ADD COLUMN "CPZ" character varying(40) COLLATE pg_catalog."default";
=======
    ADD COLUMN IF NOT EXISTS "MaxStayID" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "NoReturnID" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "CPZ" character varying(40) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Bays"
SET "CPZ" = "Zone_name";

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
>>>>>>> Stashed changes:DATAMODEL/Geojson/1003b_add_required_attributes.sql
