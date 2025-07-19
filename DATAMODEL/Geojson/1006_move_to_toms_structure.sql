
--ALTER TABLE toms."Bays" DISABLE TRIGGER update_capacity_bays;
-- DELETE FROM toms."Bays";

ALTER TABLE IF EXISTS toms."Bays"
    ADD COLUMN IF NOT EXISTS "ogc_fid" integer;
	
--ALTER SEQUENCE toms."Bays_id_seq" RESTART WITH 1;

INSERT INTO toms."Bays"(
	geom, "RoadName", "RestrictionID", "GeometryID", "RestrictionTypeID", "TimePeriodID",  "MaxStayID", "NoReturnID", "GeomShapeID", "NrBays", "CPZ", "ogc_fid")
SELECT geom, 
    "Street_name", uuid_generate_v4(), "GeometryID", "RestrictionTypeID", COALESCE("TimePeriodID", 0),  "MaxStayID", "NoReturnID", "GeomShapeID", COALESCE("NrBays", -1), "CPZ", "ogc_fid"
	FROM import_geojson."Imported_Bays";

--ALTER TABLE toms."Bays" ENABLE TRIGGER update_capacity_bays;

--ALTER TABLE toms."Lines" DISABLE TRIGGER update_capacity_lines;

-- DELETE FROM toms."Lines";
ALTER TABLE IF EXISTS toms."Lines"
    ADD COLUMN IF NOT EXISTS "ogc_fid" integer;

--ALTER SEQUENCE toms."Lines_id_seq" RESTART WITH 1;

INSERT INTO toms."Lines"(
	geom, "RoadName", "RestrictionID", "GeometryID", "RestrictionTypeID", "NoWaitingTimeID", "NoLoadingTimeID", "GeomShapeID", "CPZ", "ogc_fid")
SELECT geom, 
    "Street_name", uuid_generate_v4(), "GeometryID", "RestrictionTypeID", COALESCE("NoWaitingTimeID", 0),  "NoLoadingTimeID", "GeomShapeID", "CPZ", "ogc_fid"
	FROM import_geojson."Imported_Lines";


--ALTER TABLE toms."Lines" ENABLE TRIGGER update_capacity_lines;

/***

Add some typical defaults

***/

-- set NrBays for Bus Stops, Cycle hire, etc

UPDATE toms."Bays"
SET "NrBays" = -1
WHERE "RestrictionTypeID" IN (107, 116, 119);
