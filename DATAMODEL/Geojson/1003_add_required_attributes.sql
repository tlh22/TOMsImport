/***
 * Now add GeometryID, etc

 ***/

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Lines"
SET "GeometryID" = gid;

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

--

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeometryID" = gid;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "RestrictionTypeID" integer;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "GeomShapeID" integer;

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