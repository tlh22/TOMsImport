-- echelon bays

UPDATE local_authority."Bays_Transfer"
SET "GeomShapeID" = 5
WHERE "GeomShapeID" < 10
AND "bEchelon" = 'Y';

UPDATE local_authority."Bays_Transfer"
SET "GeomShapeID" = 25
WHERE "GeomShapeID" < 20
AND "bEchelon" = 'Y';


-- take the tables with the processed records and move them to TOMs structure
INSERT INTO "toms_lookups"."TimePeriodsInUse" ("Code")
SELECT u."TimePeriodID"
FROM (
SELECT DISTINCT "TimePeriodID"
FROM local_authority."PM_BayRestrictions_processed"
WHERE "TimePeriodID" IS NOT NULL
UNION
SELECT DISTINCT "TimePeriodID"
FROM local_authority."PM_LineRestrictions_processed"
WHERE "TimePeriodID" IS NOT NULL ) u
WHERE u."TimePeriodID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."TimePeriodsInUse"
);

INSERT INTO "toms_lookups"."BayTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT l."RestrictionTypeID", 'LineString'
FROM local_authority."PM_BayRestrictions_processed" l
WHERE l."RestrictionTypeID" IS NOT NULL
AND l."RestrictionTypeID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."BayTypesInUse"
);

INSERT INTO "toms_lookups"."LineTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT l."RestrictionTypeID", 'LineString'
FROM local_authority."PM_LineRestrictions_processed" l
WHERE l."RestrictionTypeID" IS NOT NULL
AND l."RestrictionTypeID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."LineTypesInUse"
);

--ALTER TABLE toms."Bays" DISABLE TRIGGER update_capacity_bays;

ALTER TABLE toms."Bays"
    ADD COLUMN "item_ref" integer;
ALTER TABLE toms."Bays"
    ADD COLUMN "RBKC_NrBays" integer;
	
INSERT INTO toms."Bays"(
	geom, "RoadName", "RBKC_NrBays", "RestrictionID", "GeometryID", "RestrictionTypeID", "TimePeriodID",  "GeomShapeID", "item_ref")
SELECT (ST_Dump(geom)).geom AS geom, 
    "Street_nam", "bNoBays", uuid_generate_v4(), "GeometryID", "RestrictionTypeID", "TimePeriodID",  "GeomShapeID", "item_ref"
	FROM local_authority."Bays_Transfer";

--ALTER TABLE toms."Bays" ENABLE TRIGGER update_capacity_bays;

--ALTER TABLE toms."Lines" DISABLE TRIGGER update_capacity_lines;

ALTER TABLE toms."Lines"
    ADD COLUMN "item_ref" integer;

INSERT INTO toms."Lines"(
	geom, "RoadName", "RestrictionID", "GeometryID", "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID", "item_ref")
SELECT (ST_Dump(geom)).geom AS geom, 
    "Street_nam", uuid_generate_v4(), "GeometryID", "RestrictionTypeID", "TimePeriodID",  "GeomShapeID", "item_ref"
	FROM local_authority."Lines_Transfer";


--ALTER TABLE toms."Lines" ENABLE TRIGGER update_capacity_lines;

-- Need to add Open date ...

-- echelon bays

<<<<<<< Updated upstream
UPDATE toms."Bays" AS r
SET "GeomShapeID" = t."GeomShapeID"
FROM local_authority."Bays_Transfer" t
WHERE t."item_ref" = r."item_ref";
=======
-- Ensure all codes are available


-- Bays
INSERT INTO "toms_lookups"."BayTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT l."RestrictionTypeID", 'LineString'
FROM mhtc_operations."Supply_2022" l
WHERE l."RestrictionTypeID" < 200
AND l."RestrictionTypeID" IS NOT NULL
AND l."RestrictionTypeID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."BayTypesInUse"
);

-- Lines
INSERT INTO "toms_lookups"."LineTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT l."RestrictionTypeID" l, 'LineString'
FROM mhtc_operations."Supply_2022" l
WHERE l."RestrictionTypeID" > 200
AND l."RestrictionTypeID" IS NOT NULL
AND l."RestrictionTypeID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."LineTypesInUse"
);

-- TimePeriods
INSERT INTO "toms_lookups"."TimePeriodsInUse" ("Code")
SELECT u."TimePeriodID"
FROM (
SELECT DISTINCT "TimePeriodID"
FROM mhtc_operations."Supply_2022"
WHERE "TimePeriodID" IS NOT NULL
UNION
SELECT DISTINCT "NoWaitingTimeID" as "TimePeriodID"
FROM mhtc_operations."Supply_2022"
WHERE "NoWaitingTimeID" IS NOT NULL ) u
WHERE u."TimePeriodID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."TimePeriodsInUse"
);

-- take the tables with the processed records and move them to TOMs structure

ALTER TABLE toms."Bays" DISABLE TRIGGER all;
ALTER TABLE toms."Lines" DISABLE TRIGGER all;

ALTER TABLE IF EXISTS toms."Bays"
    ADD COLUMN IF NOT EXISTS "GeometryID_previousSurvey" character varying(12) COLLATE pg_catalog."default";

INSERT INTO toms."Bays"(
	"GeometryID", geom, "RoadName", "NrBays", "RestrictionID", "RestrictionTypeID", "TimePeriodID",
	"GeomShapeID", "AzimuthToRoadCentreLine", "BayOrientation", "RestrictionLength", "GeometryID_previousSurvey")
SELECT DISTINCT on (s."GeometryID") s."GeometryID", s.geom, "RoadName", "NrBays", uuid_generate_v4(), "RestrictionTypeID", "TimePeriodID",
    "GeomShapeID", "AzimuthToRoadCentreLine", "BayOrientation", ST_Length(s.geom), s."GeometryID"
FROM mhtc_operations."Supply_2022" s, mhtc_operations."RBKC_item_ref_links_2022" l
WHERE s."RestrictionTypeID" < 200
AND s."GeometryID" = l."GeometryID"
AND item_ref IN
(SELECT DISTINCT item_ref
FROM local_authority."PM_Lines_Transfer_Current_101")
;

ALTER TABLE IF EXISTS toms."Lines"
    ADD COLUMN IF NOT EXISTS "GeometryID_previousSurvey" character varying(12) COLLATE pg_catalog."default";

INSERT INTO toms."Lines"(
	"GeometryID", geom, "RoadName", "RestrictionID", "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID",
	"AzimuthToRoadCentreLine", "UnacceptableTypeID", "RestrictionLength", "GeometryID_previousSurvey")
SELECT DISTINCT on (s."GeometryID") s."GeometryID", s.geom, "RoadName", uuid_generate_v4(), "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID",
    "AzimuthToRoadCentreLine", "UnacceptableTypeID", ST_Length(s.geom), s."GeometryID"
FROM mhtc_operations."Supply_2022" s, mhtc_operations."RBKC_item_ref_links_2022" l
WHERE s."RestrictionTypeID" > 200
AND s."GeometryID" = l."GeometryID"
AND item_ref IN
(SELECT DISTINCT item_ref
FROM local_authority."PM_Lines_Transfer_Current_101")
;

ALTER TABLE toms."Bays" ENABLE TRIGGER create_geometryid_bays;
ALTER TABLE toms."Lines" ENABLE TRIGGER create_geometryid_lines;

***/

/***
-- Forgot to include BayOrientation in original

UPDATE toms."Bays" r
SET "BayOrientation" = o."BayOrientation"
FROM mhtc_operations."Supply_2022" o
WHERE r."BayOrientation" IS NULL
AND o."GeometryID" = r."GeometryID_previousSurvey"
AND r."GeomShapeID" IN (5,9,25,29)

***/
/***
-- Additional restrictions

    107	"Bus Stop"
    109	"Buses Only Bays"
    115	"Red Route/Greenway - Loading Bay/Disabled Bay"
    116	"Cycle Hire bay"
    122	"Bus Stand"
    128	"Red Route/Greenway - Loading Bay"
    160	"Red Route/Greenway - Disabled Bay"
    161	"Red Route/Greenway - Bus Stop"
    162	"Red Route/Greenway - Bus Stand"
    163	"Red Route/Greenway - Coach Bay"
    164	"Red Route/Greenway - Taxi Rank"
***/

/***


SELECT "GeometryID", "RestrictionTypeID",
s."GeometryID", s.geom, "RoadName", "NrBays", uuid_generate_v4(), "RestrictionTypeID", "TimePeriodID",
    "GeomShapeID", "AzimuthToRoadCentreLine", "BayOrientation", ST_Length(s.geom), s."GeometryID"
FROM mhtc_operations."Supply_2022" s
WHERE s."RestrictionTypeID" < 200
AND s."GeometryID" NOT IN (
SELECT "GeometryID" FROM mhtc_operations."RBKC_item_ref_links_2022")


INSERT INTO toms."Bays"(
	"GeometryID", geom, "RoadName", "NrBays", "RestrictionID", "RestrictionTypeID", "TimePeriodID",
	"GeomShapeID", "AzimuthToRoadCentreLine", "BayOrientation", "RestrictionLength", "GeometryID_previousSurvey")
SELECT DISTINCT on (s."GeometryID") s."GeometryID", s.geom, "RoadName", "NrBays", uuid_generate_v4(), "RestrictionTypeID", "TimePeriodID",
    "GeomShapeID", "AzimuthToRoadCentreLine", "BayOrientation", ST_Length(s.geom), s."GeometryID"
FROM mhtc_operations."Supply_2022" s
WHERE s."RestrictionTypeID" < 200
AND s."GeometryID" NOT IN (
SELECT "GeometryID" FROM mhtc_operations."RBKC_item_ref_links_2022")
;

***/

/***



SELECT DISTINCT s."RestrictionTypeID", l."Description"
FROM mhtc_operations."Supply_2022" s, toms_lookups."BayLineTypes" l
WHERE s."RestrictionTypeID" > 200
AND s."RestrictionTypeID" = l."Code"
AND s."GeometryID" NOT IN (
SELECT "GeometryID" FROM mhtc_operations."RBKC_item_ref_links_2022")
ORDER BY "RestrictionTypeID"

SELECT s."GeometryID", s.geom, "RoadName", uuid_generate_v4(), "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID",
    "AzimuthToRoadCentreLine", "UnacceptableTypeID", ST_Length(s.geom), s."GeometryID"
FROM mhtc_operations."Supply_2022" s
WHERE s."RestrictionTypeID" > 200
--AND s."RestrictionTypeID" IN (202)
AND s."GeometryID" NOT IN (
SELECT "GeometryID" FROM mhtc_operations."RBKC_item_ref_links_2022")
ORDER BY "RestrictionTypeID"


INSERT INTO toms."Lines"(
	"GeometryID", geom, "RoadName", "RestrictionID", "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID",
    "AzimuthToRoadCentreLine", "UnacceptableTypeID", "RestrictionLength", "GeometryID_previousSurvey")
SELECT DISTINCT on (s."GeometryID") s."GeometryID", s.geom, "RoadName", uuid_generate_v4(), "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID",
    "AzimuthToRoadCentreLine", "UnacceptableTypeID", ST_Length(s.geom), s."GeometryID"
FROM mhtc_operations."Supply_2022" s
WHERE s."RestrictionTypeID" > 200
--AND "RestrictionTypeID" NOT IN (201, 221)
AND s."GeometryID" NOT IN (
SELECT "GeometryID" FROM mhtc_operations."RBKC_item_ref_links_2022")
AND s."GeometryID" NOT IN (SELECT "GeometryID" FROM toms."Lines")
;

***/
-- check for overlaps
/***
DROP TABLE IF EXISTS mhtc_operations."Bay_Overlaps";

CREATE TABLE mhtc_operations."Bay_Overlaps"
(
    id SERIAL,
    "GeometryID_1" character varying(12) COLLATE pg_catalog."default" NOT NULL,
	"RestrictionTypeID_1" integer,
    "GeometryID_2" character varying(12) COLLATE pg_catalog."default" NOT NULL,
	"RestrictionTypeID_2" integer,
	"RoadName" character varying(254) COLLATE pg_catalog."default",
	"LengthOfOverlap" double precision,
    geom geometry(geometry, 27700) NOT NULL,
    CONSTRAINT "Supply_Overlaps_pkey" PRIMARY KEY ("id")
)

TABLESPACE pg_default;

ALTER TABLE mhtc_operations."Bay_Overlaps"
    OWNER to postgres;

INSERT INTO mhtc_operations."Bay_Overlaps" ("GeometryID_1", "RestrictionTypeID_1", "GeometryID_2", "RestrictionTypeID_2", "RoadName", "LengthOfOverlap", geom)
SELECT s1."GeometryID" AS "GeometryID_1", s1."RestrictionTypeID" AS "RestrictionTypeID_1",
s2."GeometryID"  AS "GeometryID_2", s2."RestrictionTypeID" AS "RestrictionTypeID_2", s1."RoadName", ST_Length(ST_Intersection(s1.geom, s2.geom)) AS "LengthOfOverlap", ST_Intersection(s1.geom, s2.geom) AS geom
FROM toms."Bays" s1, toms."Bays" s2
WHERE ST_INTERSECTS(ST_LineSubstring (s1.geom, 0.1, 0.9), ST_Buffer(s2.geom, 0.1, 'endcap=flat'))
AND s1."GeometryID" < s2."GeometryID"
AND s1."GeomShapeID" < 100
AND s2."GeomShapeID" < 100
ORDER BY s1."GeometryID", s1."RoadName";

GRANT ALL ON TABLE mhtc_operations."Bay_Overlaps" TO postgres;

-- Output

SELECT "GeometryID_1", "BayLineTypes1"."Description" AS "RestrictionType Description",
       "GeometryID_2", "BayLineTypes2"."Description" AS "RestrictionType Description", "RoadName", "LengthOfOverlap"
FROM mhtc_operations."Bay_Overlaps" so
     LEFT JOIN "toms_lookups"."BayLineTypes" AS "BayLineTypes1" ON so."RestrictionTypeID_1" is not distinct from "BayLineTypes1"."Code"
	 LEFT JOIN "toms_lookups"."BayLineTypes" AS "BayLineTypes2" ON so."RestrictionTypeID_2" is not distinct from "BayLineTypes2"."Code"
;
***/
>>>>>>> Stashed changes
