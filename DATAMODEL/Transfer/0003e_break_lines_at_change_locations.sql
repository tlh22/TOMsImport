/***


***/

DROP TABLE IF EXISTS mhtc_operations."Lines_2" CASCADE;

CREATE TABLE mhtc_operations."Lines_2"
(
    "RestrictionID" character varying(254) COLLATE pg_catalog."default" NOT NULL,
    "GeometryID" character varying(12) COLLATE pg_catalog."default" NOT NULL DEFAULT ('L_'::text || to_char(nextval('toms."Lines_id_seq"'::regclass), 'FM0000000'::text)),
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
    "LastUpdateDateTime" timestamp without time zone NOT NULL DEFAULT now(),
    "LastUpdatePerson" character varying(255) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    "NoWaitingTimeID" integer,
    "NoLoadingTimeID" integer,
    "UnacceptableTypeID" integer,
    "AdditionalConditionID" integer,
    "ParkingTariffArea" character varying(10) COLLATE pg_catalog."default",
    "labelLoading_Rotation" double precision,
    "ComplianceRoadMarkingsFaded" integer,
    "ComplianceRestrictionSignIssue" integer,
    "ComplianceNotes" character varying(254) COLLATE pg_catalog."default",
    "MHTC_CheckIssueTypeID" integer,
    "MHTC_CheckNotes" character varying(254) COLLATE pg_catalog."default",
    "ComplianceLoadingMarkingsFaded" integer,
    "MatchDayTimePeriodID" integer,
    "CreateDateTime" timestamp without time zone NOT NULL DEFAULT now(),
    "CreatePerson" character varying(255) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    "Capacity" integer,
    label_pos geometry(MultiPoint,27700),
    label_ldr geometry(MultiLineString,27700),
    label_loading_pos geometry(MultiPoint,27700),
    label_loading_ldr geometry(MultiLineString,27700),
    "MatchDayEventDayZone" character varying(40) COLLATE pg_catalog."default",
    "DisplayLabel" boolean NOT NULL DEFAULT true,
    item_ref integer,
    "GeometryID_previousSurvey" character varying(12) COLLATE pg_catalog."default",
    CONSTRAINT "Lines_2_pkey" PRIMARY KEY ("RestrictionID"),
    CONSTRAINT "Lines_2_GeometryID_key" UNIQUE ("GeometryID")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS mhtc_operations."Lines_2"
    OWNER to postgres;

--- populate

INSERT INTO mhtc_operations."Lines_2"(
	"RestrictionID", "GeometryID", geom, "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
	"Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
	"LastUpdateDateTime", "LastUpdatePerson", "NoWaitingTimeID", "NoLoadingTimeID", "UnacceptableTypeID", "AdditionalConditionID", "ParkingTariffArea",
	"labelLoading_Rotation", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
	"MHTC_CheckNotes", "ComplianceLoadingMarkingsFaded", "MatchDayTimePeriodID", "CreateDateTime", "CreatePerson", "Capacity",
	label_pos, label_ldr, label_loading_pos, label_loading_ldr, "MatchDayEventDayZone", "DisplayLabel", item_ref, "GeometryID_previousSurvey")
SELECT "RestrictionID", "GeometryID", geom, "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
    "Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
    "LastUpdateDateTime", "LastUpdatePerson", "NoWaitingTimeID", "NoLoadingTimeID", "UnacceptableTypeID", "AdditionalConditionID", "ParkingTariffArea",
    "labelLoading_Rotation", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
    "MHTC_CheckNotes", "ComplianceLoadingMarkingsFaded", "MatchDayTimePeriodID", "CreateDateTime", "CreatePerson", "Capacity",
    label_pos, label_ldr, label_loading_pos, label_loading_ldr, "MatchDayEventDayZone", "DisplayLabel", item_ref, "GeometryID_previousSurvey"
	FROM toms."Lines";

CREATE INDEX "sidx_Lines_2_geom"
  ON mhtc_operations."Lines_2"
  USING gist
  (geom);

-- set up crossover nodes table
DROP TABLE IF EXISTS  mhtc_operations."LineNodes" CASCADE;

CREATE TABLE mhtc_operations."LineNodes"
(
  id SERIAL,
  geom public.geometry(Point,27700),
  CONSTRAINT "LineNodes_pkey" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE mhtc_operations."LineNodes"
  OWNER TO postgres;
GRANT ALL ON TABLE mhtc_operations."LineNodes" TO postgres;

CREATE INDEX "sidx_LineNodes_geom"
  ON mhtc_operations."LineNodes"
  USING gist
  (geom);


INSERT INTO mhtc_operations."LineNodes" (geom)
SELECT ST_StartPoint(geom) As geom
FROM local_authority."Lines_Transfer";

INSERT INTO mhtc_operations."LineNodes" (geom)
SELECT ST_EndPoint(geom) As geom
FROM local_authority."Lines_Transfer";

-- Make "blade" public.geometry

DROP TABLE IF EXISTS  mhtc_operations."LineNodes_Single" CASCADE;

CREATE TABLE mhtc_operations."LineNodes_Single"
(
  id SERIAL,
  geom public.geometry(MultiPoint,27700),
  CONSTRAINT "LineNodes_Single_pkey" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE mhtc_operations."LineNodes_Single"
  OWNER TO postgres;
GRANT ALL ON TABLE mhtc_operations."LineNodes_Single" TO postgres;

CREATE INDEX "sidx_LineNodes_Single_geom"
  ON mhtc_operations."LineNodes_Single"
  USING gist
  (geom);

INSERT INTO mhtc_operations."LineNodes_Single" (geom)
SELECT ST_Multi(ST_Collect(geom)) As geom
FROM mhtc_operations."LineNodes";

-- ***

DELETE FROM toms."Lines";

--

INSERT INTO toms."Lines"(
	"RestrictionID", "GeometryID", "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
	"Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
	"LastUpdateDateTime", "LastUpdatePerson", "NoWaitingTimeID", "NoLoadingTimeID", "UnacceptableTypeID", "AdditionalConditionID", "ParkingTariffArea",
	"labelLoading_Rotation", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
	"MHTC_CheckNotes", "ComplianceLoadingMarkingsFaded", "MatchDayTimePeriodID", "CreateDateTime", "CreatePerson", "Capacity",
	label_pos, label_ldr, label_loading_pos, label_loading_ldr, "MatchDayEventDayZone", "DisplayLabel", item_ref, "GeometryID_previousSurvey", geom)
SELECT uuid_generate_v4(), "GeometryID", "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
    "Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
    "LastUpdateDateTime", "LastUpdatePerson", "NoWaitingTimeID", "NoLoadingTimeID", "UnacceptableTypeID", "AdditionalConditionID", "ParkingTariffArea",
    "labelLoading_Rotation", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
    "MHTC_CheckNotes", "ComplianceLoadingMarkingsFaded", "MatchDayTimePeriodID", "CreateDateTime", "CreatePerson", "Capacity",
    label_pos, label_ldr, label_loading_pos, label_loading_ldr, "MatchDayEventDayZone", "DisplayLabel", item_ref, "GeometryID_previousSurvey",
    (ST_Dump(ST_Split(s1.geom, ST_Buffer(c.geom, 0.00001)))).geom
FROM mhtc_operations."Lines_2" s1, (SELECT ST_Union(ST_Snap(cnr.geom, s1.geom, 0.00000001)) AS geom
									  FROM mhtc_operations."Lines_2" s1,
                                          (SELECT geom
                                          FROM mhtc_operations."LineNodes_Single"
                                          ) cnr
									  ) c
WHERE ST_DWithin(s1.geom, c.geom, 0.25)
union
SELECT
    uuid_generate_v4(), "GeometryID", "RestrictionLength", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "Notes",
    "Photos_01", "Photos_02", "Photos_03", "RoadName", "USRN", "label_Rotation", "label_TextChanged", "OpenDate", "CloseDate", "CPZ",
    "LastUpdateDateTime", "LastUpdatePerson", "NoWaitingTimeID", "NoLoadingTimeID", "UnacceptableTypeID", "AdditionalConditionID", "ParkingTariffArea",
    "labelLoading_Rotation", "ComplianceRoadMarkingsFaded", "ComplianceRestrictionSignIssue", "ComplianceNotes", "MHTC_CheckIssueTypeID",
    "MHTC_CheckNotes", "ComplianceLoadingMarkingsFaded", "MatchDayTimePeriodID", "CreateDateTime", "CreatePerson", "Capacity",
    label_pos, label_ldr, label_loading_pos, label_loading_ldr, "MatchDayEventDayZone", "DisplayLabel", item_ref, "GeometryID_previousSurvey",
    s1.geom
FROM mhtc_operations."Lines_2" s1, (SELECT ST_Union(ST_Snap(cnr.geom, s1.geom, 0.00000001)) AS geom
									  FROM mhtc_operations."Lines_2" s1,
                                          (SELECT geom
                                          FROM mhtc_operations."LineNodes_Single"
                                          ) cnr
									  ) c
WHERE NOT ST_DWithin(s1.geom, c.geom, 0.25)
;

DELETE FROM toms."Lines"
WHERE ST_Length(geom) < 0.01;

-- Check time periods
UPDATE "toms"."Lines" AS s1
SET "NoWaitingTimeID" = s2."TimePeriodID"
FROM local_authority."Lines_Transfer" s2
WHERE s1.item_ref = s2.item_ref
AND s1."NoWaitingTimeID" != "TimePeriodID";

/***

-- check for overlaps

DROP TABLE IF EXISTS mhtc_operations."Line_Overlaps";

CREATE TABLE mhtc_operations."Line_Overlaps"
(
    id SERIAL,
    "GeometryID_1" character varying(12) COLLATE pg_catalog."default" NOT NULL,
	"RestrictionTypeID_1" integer,
    "GeometryID_2" character varying(12) COLLATE pg_catalog."default" NOT NULL,
	"RestrictionTypeID_2" integer,
	"RoadName" character varying(254) COLLATE pg_catalog."default",
	"LengthOfOverlap" double precision,
    geom geometry(geometry, 27700) NOT NULL,
    CONSTRAINT "Line_Overlaps_pkey" PRIMARY KEY ("id")
)

TABLESPACE pg_default;

ALTER TABLE mhtc_operations."Line_Overlaps"
    OWNER to postgres;

INSERT INTO mhtc_operations."Line_Overlaps" ("GeometryID_1", "RestrictionTypeID_1", "GeometryID_2", "RestrictionTypeID_2", "RoadName", "LengthOfOverlap", geom)
SELECT s1."GeometryID" AS "GeometryID_1", s1."RestrictionTypeID" AS "RestrictionTypeID_1",
s2."GeometryID"  AS "GeometryID_2", s2."RestrictionTypeID" AS "RestrictionTypeID_2", s1."RoadName", ST_Length(ST_Intersection(s1.geom, s2.geom)) AS "LengthOfOverlap", ST_Intersection(s1.geom, s2.geom) AS geom
FROM toms."Lines" s1, toms."Lines" s2
WHERE ST_INTERSECTS(ST_LineSubstring (s1.geom, 0.1, 0.9), ST_Buffer(s2.geom, 0.1, 'endcap=flat'))
AND s1."GeometryID" < s2."GeometryID"
AND s1."GeomShapeID" < 100
AND s2."GeomShapeID" < 100
ORDER BY s1."GeometryID", s1."RoadName";

GRANT ALL ON TABLE mhtc_operations."Line_Overlaps" TO postgres;

-- Output

SELECT "GeometryID_1", "BayLineTypes1"."Description" AS "RestrictionType Description",
       "GeometryID_2", "BayLineTypes2"."Description" AS "RestrictionType Description", "RoadName", "LengthOfOverlap"
FROM mhtc_operations."Line_Overlaps" so
     LEFT JOIN "toms_lookups"."BayLineTypes" AS "BayLineTypes1" ON so."RestrictionTypeID_1" is not distinct from "BayLineTypes1"."Code"
	 LEFT JOIN "toms_lookups"."BayLineTypes" AS "BayLineTypes2" ON so."RestrictionTypeID_2" is not distinct from "BayLineTypes2"."Code"
;
***/


-- Change line details - RestrictionTypeID ??

UPDATE "toms"."Lines" AS s1
SET "RestrictionTypeID" = s2."RestrictionTypeID"
    , "TimePeriodID" = s2."bNoBays"
    , item_ref = s2."item_ref"
    , "RBKC_NrBays" = s2."bNoBays"
FROM local_authority."Lines_Transfer" s2
WHERE ST_Within(s1.geom, ST_Buffer(s2.geom, 0.1));


-- now want features that have been divided ...

/***
logic:

    get the restrictions that are changed but not assigned new bay counts
    and where the number of bays in those restrictions is > 0 (so the bays count will need to be changed)

        get the restrictions that are within the changed area
        sum the number of bays
        update the nr of bays

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
        SELECT "GeometryID", "orig_GeometryID", r."NrBays"
        FROM toms."Bays" r, mhtc_operations."BayNodes_Single" n
        WHERE ST_DWithin(r.geom, n.geom, 0.25)
        AND "RBKC_NrBays" IS NULL
        AND "NrBays" > 0

    LOOP

        orig_geometry_id = new_restriction."orig_GeometryID";
        amended_restriction_geometry_id = new_restriction."GeometryID";

        SELECT SUM("RBKC_NrBays")
        INTO nrChangedBays
        FROM "toms"."Bays" r
        WHERE r."orig_GeometryID" = orig_geometry_id
        ;

        UPDATE "toms"."Bays"
        SET "NrBays" =
            CASE WHEN "NrBays" > 0 THEN
                "NrBays" - nrChangedBays
            ELSE "NrBays"
        END
        WHERE "GeometryID" = amended_restriction_geometry_id;

        RAISE NOTICE '***** amended restriction: (%); nrBays (%)', amended_restriction_geometry_id, new_restriction."NrBays"-nrChangedBays;

    END LOOP;

END
$do$;


