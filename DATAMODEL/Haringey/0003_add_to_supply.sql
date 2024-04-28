/***

Add details to Supply

***/

-- Save processed tmp details to mhtc_operations."tmpSupply"
-- and deal with any missing data

-- Add extra bay/line types

INSERT INTO toms_lookups."BayTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT "RestrictionTypeID", 'Polygon'
FROM mhtc_operations."tmpSupply"
WHERE "RestrictionTypeID" < 200
AND "RestrictionTypeID" NOT IN (SELECT "Code" FROM toms_lookups."BayTypesInUse");

REFRESH MATERIALIZED VIEW "toms_lookups"."BayTypesInUse_View";

INSERT INTO toms_lookups."LineTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT "RestrictionTypeID", 'LineString'
FROM mhtc_operations."tmpSupply"
WHERE "RestrictionTypeID" > 200
AND "RestrictionTypeID" NOT IN (SELECT "Code" FROM toms_lookups."LineTypesInUse");

REFRESH MATERIALIZED VIEW "toms_lookups"."LineTypesInUse_View";

-- sort out GeomShape

UPDATE mhtc_operations."tmpSupply" As s
SET "GeomShapeID" = 21
FROM toms_lookups."BayTypesInUse" l
WHERE s."RestrictionTypeID" = l."Code"
AND "GeomShapeGroupType" = 'Polygon';

UPDATE mhtc_operations."tmpSupply" As s
SET "GeomShapeID" = 1
FROM toms_lookups."BayTypesInUse" l
WHERE s."RestrictionTypeID" = l."Code"
AND "GeomShapeGroupType" = 'LineString';

UPDATE mhtc_operations."tmpSupply" As s
SET "GeomShapeID" = 10
FROM toms_lookups."LineTypesInUse" l
WHERE s."RestrictionTypeID" = l."Code"
AND "GeomShapeGroupType" = 'LineString';

-- run plugins\restrictionsWithGNSS\DATAMODEL\DemandSetup\0003a1_create_supply_table.sql

ALTER TABLE mhtc_operations."Supply"
    ADD COLUMN "tmpGeometryID" character varying COLLATE pg_catalog."default";

INSERT INTO mhtc_operations."Supply"(
	geom, "RoadName", "GeometryID", "RestrictionTypeID", "GeomShapeID", "tmpGeometryID")
SELECT (ST_Dump(geom)).geom AS geom,
    "RoadName", "GeometryID", "RestrictionTypeID", "GeomShapeID", "GeometryID"
	FROM mhtc_operations."tmpSupply";

UPDATE mhtc_operations."Supply" s
SET "TimePeriodID" = l."TimePeriodID",
    "MaxStayID" = l."MaxStayID",
    "NoReturnID" = l."NoReturnID",
    "MatchDayTimePeriodID" = l."MatchDayTimePeriodID",
    "NoWaitingTimeID" = l."NoWaitingTimeID",
    "NoLoadingTimeID" = l."NoLoadingTimeID"
FROM local_authority."tmp_All_Data" l
WHERE s."tmpGeometryID" = l."GeometryID";