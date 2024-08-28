/***


***/

DROP TABLE IF EXISTS mhtc_operations."Bays_2" CASCADE;

CREATE TABLE mhtc_operations."Bays_2"
(
    "RestrictionID" character varying(254) COLLATE pg_catalog."default" NOT NULL,
    "GeometryID" character varying(12) COLLATE pg_catalog."default" NOT NULL DEFAULT ('B_'::text || to_char(nextval('toms."Bays_id_seq"'::regclass), 'FM0000000'::text)),
    geom geometry(LineString,27700) NOT NULL,
    "RestrictionLength" double precision NOT NULL,
    "RestrictionTypeID" integer NOT NULL,
    "GeomShapeID" integer NOT NULL,
    "AzimuthToRoadCentreLine" double precision,
    "Notes" character varying(254) COLLATE pg_catalog."default",
    "Photos_01" character varying(255) COLLATE pg_catalog."default",
    "Photos_02" character varying(255) COLLATE pg_catalog."default",
    "Photos_03" character varying(255) COLLATE pg_catalog."default",
    "RoadName" character varying(254) COLLATE pg_catalog."default",
    "USRN" character varying(254) COLLATE pg_catalog."default",
    "label_Rotation" double precision,
    "label_TextChanged" character varying(254) COLLATE pg_catalog."default",
    "OpenDate" date,
    "CloseDate" date,
    "CPZ" character varying(40) COLLATE pg_catalog."default",
    "LastUpdateDateTime" timestamp without time zone NOT NULL,
    "LastUpdatePerson" character varying(255) COLLATE pg_catalog."default" NOT NULL,
    "BayOrientation" double precision,
    "NrBays" integer NOT NULL DEFAULT '-1'::integer,
    "TimePeriodID" integer NOT NULL,
    "PayTypeID" integer,
    "MaxStayID" integer,
    "NoReturnID" integer,
    "ParkingTariffArea" character varying(10) COLLATE pg_catalog."default",
    "AdditionalConditionID" integer,
    "ComplianceRoadMarkingsFaded" integer,
    "ComplianceRestrictionSignIssue" integer,
    "ComplianceNotes" character varying(254) COLLATE pg_catalog."default",
    "MHTC_CheckIssueTypeID" integer,
    "MHTC_CheckNotes" character varying(254) COLLATE pg_catalog."default",
    "PermitCode" character varying(255) COLLATE pg_catalog."default",
    "MatchDayTimePeriodID" integer,
    "PayParkingAreaID" integer,
    "CreateDateTime" timestamp without time zone NOT NULL,
    "CreatePerson" character varying(255) COLLATE pg_catalog."default" NOT NULL,
    "Capacity" integer,
    label_pos geometry(MultiPoint,27700),
    label_ldr geometry(MultiLineString,27700),
    "MatchDayEventDayZone" character varying(40) COLLATE pg_catalog."default",
    "BayWidth" double precision,
    "DisplayLabel" boolean NOT NULL DEFAULT true,
    item_ref integer,
    "RBKC_NrBays" integer,
    "GeometryID_previousSurvey" character varying(12) COLLATE pg_catalog."default",
    CONSTRAINT "Bays_2_pkey" PRIMARY KEY ("RestrictionID"),
    CONSTRAINT "Bays_2_GeometryID_key" UNIQUE ("GeometryID")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS mhtc_operations."Bays_2"
    OWNER to postgres;

--- populate

INSERT INTO mhtc_operations."Bays_2"(
	"RestrictionID", "GeometryID", geom, "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
	"Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
	"LastUpdateDateTime", "LastUpdatePerson", "BayOrientation", "NrBays", "TimePeriodID", "PayTypeID", "MaxStayID", "NoReturnID", "ParkingTariffArea",
	"AdditionalConditionID", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
	"MHTC_CheckNotes", "PermitCode", "MatchDayTimePeriodID", "PayParkingAreaID", "CreateDateTime", "CreatePerson", "Capacity",
	label_pos, label_ldr, "MatchDayEventDayZone", "BayWidth", "DisplayLabel", item_ref, "RBKC_NrBays", "GeometryID_previousSurvey")
SELECT "RestrictionID", "GeometryID", geom, "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
    "Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
    "LastUpdateDateTime", "LastUpdatePerson", "BayOrientation", "NrBays", "TimePeriodID", "PayTypeID", "MaxStayID", "NoReturnID", "ParkingTariffArea",
    "AdditionalConditionID", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
    "MHTC_CheckNotes", "PermitCode", "MatchDayTimePeriodID", "PayParkingAreaID", "CreateDateTime", "CreatePerson", "Capacity",
    label_pos, label_ldr, "MatchDayEventDayZone", "BayWidth", "DisplayLabel", item_ref, "RBKC_NrBays", "GeometryID_previousSurvey"
	FROM toms."Bays";

CREATE INDEX "sidx_Bays_2_geom"
  ON mhtc_operations."Bays_2"
  USING gist
  (geom);

-- set up crossover nodes table
DROP TABLE IF EXISTS  mhtc_operations."BayNodes" CASCADE;

CREATE TABLE mhtc_operations."BayNodes"
(
  id SERIAL,
  geom public.geometry(Point,27700),
  CONSTRAINT "BayNodes_pkey" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE mhtc_operations."BayNodes"
  OWNER TO postgres;
GRANT ALL ON TABLE mhtc_operations."BayNodes" TO postgres;

CREATE INDEX "sidx_BayNodes_geom"
  ON mhtc_operations."BayNodes"
  USING gist
  (geom);


INSERT INTO mhtc_operations."BayNodes" (geom)
SELECT ST_StartPoint(geom) As geom
FROM local_authority."Bays_Transfer";

INSERT INTO mhtc_operations."BayNodes" (geom)
SELECT ST_EndPoint(geom) As geom
FROM local_authority."Bays_Transfer";

-- Make "blade" public.geometry

DROP TABLE IF EXISTS  mhtc_operations."BayNodes_Single" CASCADE;

CREATE TABLE mhtc_operations."BayNodes_Single"
(
  id SERIAL,
  geom public.geometry(MultiPoint,27700),
  CONSTRAINT "BayNodes_Single_pkey" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE mhtc_operations."BayNodes_Single"
  OWNER TO postgres;
GRANT ALL ON TABLE mhtc_operations."BayNodes_Single" TO postgres;

CREATE INDEX "sidx_BayNodes_Single_geom"
  ON mhtc_operations."BayNodes_Single"
  USING gist
  (geom);

INSERT INTO mhtc_operations."BayNodes_Single" (geom)
SELECT ST_Multi(ST_Collect(geom)) As geom
FROM mhtc_operations."BayNodes";

-- ***

DELETE FROM toms."Bays";

--ALTER TABLE IF EXISTS toms."Bays"
--    ADD COLUMN IF NOT EXISTS "orig_GeometryID" character varying(12) COLLATE pg_catalog."default" NOT NULL;
ALTER TABLE IF EXISTS toms."Bays"
    DROP COLUMN IF EXISTS "orig_GeometryID";
--

INSERT INTO toms."Bays"(
	"RestrictionID", "GeometryID", "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
	"Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
	"LastUpdateDateTime", "LastUpdatePerson", "BayOrientation", "NrBays", "TimePeriodID", "PayTypeID", "MaxStayID", "NoReturnID", "ParkingTariffArea",
	"AdditionalConditionID", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
	"MHTC_CheckNotes", "PermitCode", "MatchDayTimePeriodID", "PayParkingAreaID", "CreateDateTime", "CreatePerson", "Capacity",
	label_pos, label_ldr, "MatchDayEventDayZone", "BayWidth", "DisplayLabel", item_ref, "RBKC_NrBays", "GeometryID_previousSurvey", --"orig_GeometryID"
	geom)
SELECT uuid_generate_v4(), "GeometryID", "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
    "Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
    "LastUpdateDateTime", "LastUpdatePerson", "BayOrientation", "NrBays", "TimePeriodID", "PayTypeID", "MaxStayID", "NoReturnID", "ParkingTariffArea",
    "AdditionalConditionID", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
    "MHTC_CheckNotes", "PermitCode", "MatchDayTimePeriodID", "PayParkingAreaID", "CreateDateTime", "CreatePerson", "Capacity",
    label_pos, label_ldr, "MatchDayEventDayZone", "BayWidth", "DisplayLabel", item_ref, "RBKC_NrBays", "GeometryID_previousSurvey", --"GeometryID",
    (ST_Dump(ST_Split(s1.geom, ST_Buffer(c.geom, 0.00001)))).geom
FROM mhtc_operations."Bays_2" s1, (SELECT ST_Union(ST_Snap(cnr.geom, s1.geom, 0.00000001)) AS geom
									  FROM mhtc_operations."Bays_2" s1,
                                          (SELECT geom
                                          FROM mhtc_operations."BayNodes_Single"
                                          ) cnr
									  ) c
WHERE ST_DWithin(s1.geom, c.geom, 0.25)
union
SELECT
    uuid_generate_v4(), "GeometryID", "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
    "Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
    "LastUpdateDateTime", "LastUpdatePerson", "BayOrientation", "NrBays", "TimePeriodID", "PayTypeID", "MaxStayID", "NoReturnID", "ParkingTariffArea",
    "AdditionalConditionID", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
    "MHTC_CheckNotes", "PermitCode", "MatchDayTimePeriodID", "PayParkingAreaID", "CreateDateTime", "CreatePerson", "Capacity",
    label_pos, label_ldr, "MatchDayEventDayZone", "BayWidth", "DisplayLabel", item_ref, "RBKC_NrBays", "GeometryID_previousSurvey", --"GeometryID",
    s1.geom
FROM mhtc_operations."Bays_2" s1, (SELECT ST_Union(ST_Snap(cnr.geom, s1.geom, 0.00000001)) AS geom
									  FROM mhtc_operations."Bays_2" s1,
                                          (SELECT geom
                                          FROM mhtc_operations."BayNodes_Single"
                                          ) cnr
									  ) c
WHERE NOT ST_DWithin(s1.geom, c.geom, 0.25)
;

DELETE FROM toms."Bays"
WHERE ST_Length(geom) < 0.01;

-- Change bay details - RestrictionTypeID and NrBays

UPDATE "toms"."Bays" AS s1
SET "RestrictionTypeID" = s2."RestrictionTypeID"
    , "NrBays" = s2."bNoBays"
    , item_ref = s2."item_ref"
    , "RBKC_NrBays" = s2."bNoBays"
FROM local_authority."Bays_Transfer" s2
WHERE ST_Within(s1.geom, ST_Buffer(s2.geom, 0.1));

-- tidy NrBays for non-marked bays

UPDATE "toms"."Bays"
SET "NrBays" = -1
WHERE "RestrictionTypeID" IN (101, 102, 104, 105, 106, 107, 109, 114, 120, 121, 122, 126, 127, 128, 129, 130, 131, 133, 134, 135, 142, 143, 161, 162, 163, 164)
AND "GeomShapeID" IN (1, 2, 3, 21, 22, 23)
AND "NrBays" > 1
AND ST_Length(geom) > 9.5;

-- tidy geom types

DO
$do$
DECLARE
    bay_type RECORD;
BEGIN

    FOR bay_type IN
        SELECT "Code", "GeomShapeGroupType"
        FROM toms_lookups."BayTypesInUse"
    LOOP

        RAISE NOTICE '***** considering type: (%)', bay_type."Code";

        UPDATE "toms"."Bays"
            SET "GeomShapeID" =
                CASE WHEN "GeomShapeID" > 20 AND bay_type."GeomShapeGroupType" = 'LineString' THEN
                        "GeomShapeID" - 20
                     WHEN "GeomShapeID" < 20 AND bay_type."GeomShapeGroupType" = 'Polygon' THEN
                        "GeomShapeID" + 20
                     ELSE "GeomShapeID"
                END
            WHERE "RestrictionTypeID" = bay_type."Code";

    END LOOP;

END
$do$;


-- now want features that have been divided ...

/***
logic:

    get the restrictions that are changed but not assigned new bay counts
    and where the number of bays in those restrictions is > 0 (so the bays count will need to be changed)

        get the restrictions that are within the changed area
        sum the number of bays
        update the nr of bays
??? not working very well ...
***/

DO
$do$
DECLARE
   new_restriction RECORD;
   orig_geometry_id text;
   amended_restriction_geometry_id text;
   nrChangedBays integer;
BEGIN

    FOR new_restriction IN
        SELECT r."GeometryID", r."GeometryID_previousSurvey", r."NrBays"
        FROM toms."Bays" r, local_authority."Bays_Transfer" t
        WHERE ST_Within (r.geom, ST_Buffer(t.geom, 0.001))
        AND r."GeometryID_previousSurvey" IS NOT NULL
        AND r."NrBays" > 0
        --AND r."GeometryID" IN ('B_0121715', 'B_0120553', 'B_0124440')
    LOOP

        orig_geometry_id = new_restriction."GeometryID_previousSurvey";
        nrChangedBays = new_restriction."NrBays";

        SELECT r."GeometryID"
        INTO amended_restriction_geometry_id
        FROM "toms"."Bays" r, local_authority."Bays_Transfer" t
        WHERE r."GeometryID_previousSurvey" = orig_geometry_id
        AND NOT ST_Within (r.geom, ST_Buffer(t.geom, 0.001));

        UPDATE "toms"."Bays"
        SET "NrBays" = "NrBays" - nrChangedBays
        WHERE "GeometryID" = amended_restriction_geometry_id
        ;

        RAISE NOTICE '***** amended restriction: (%); nrBays (%)', amended_restriction_geometry_id, new_restriction."NrBays"-nrChangedBays;

    END LOOP;

END
$do$;

-- remove original features that have been divided ..
DELETE FROM toms."Bays"
WHERE "GeometryID" IN (
SELECT r."GeometryID"
FROM toms."Bays" r, local_authority."Bays_Transfer" t
WHERE ST_Within (r.geom, ST_Buffer(t.geom, 0.001))
AND r."GeometryID_previousSurvey" IS NOT NULL
--AND r."GeometryID" IN ('B_0121715', 'B_0120553', 'B_0124440')
);

-- Check for any bays with NrBays = 0

SELECT r."GeometryID"
FROM toms."Bays"
WHERE "NrBays" = 0

-- Find any perpendicular/echelon bays that have been changed

SELECT r."GeometryID"
FROM toms."Bays" r, local_authority."Bays_Transfer" t
WHERE ST_Within (r.geom, ST_Buffer(t.geom, 0.001))
AND r."GeomShapeID" IN (4,5,9,24,25,29)

-- Need to check that merger is correct

-- Need to deal with NrBays after merger