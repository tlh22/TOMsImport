/***

Create temporary tables for all data

***/

-- DROP TABLE IF EXISTS local_authority."tmp_All_Data" CASCADE;

CREATE TABLE IF NOT EXISTS local_authority."tmp_All_Data"
(
    id SERIAL,
    geom geometry(Polygon,27700),
    order_type character varying COLLATE pg_catalog."default",
    un_id character varying COLLATE pg_catalog."default",
    street_nam character varying COLLATE pg_catalog."default",
    zone character varying COLLATE pg_catalog."default",
    "locationNu" character varying COLLATE pg_catalog."default",
    bays integer,
    "ospId" character varying COLLATE pg_catalog."default",
    ohsets character varying COLLATE pg_catalog."default",
    ohsets_description character varying COLLATE pg_catalog."default",
    tarsets character varying COLLATE pg_catalog."default",
    tarsets_description character varying COLLATE pg_catalog."default",
    excset character varying COLLATE pg_catalog."default",
    excset_description character varying COLLATE pg_catalog."default",
    exeset character varying COLLATE pg_catalog."default",
    exeset_description character varying COLLATE pg_catalog."default",
    CONSTRAINT "tmp_All_Data_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS local_authority."tmp_All_Data"
    OWNER to postgres;

CREATE INDEX IF NOT EXISTS "sidx_tmp_All_Data_geom"
    ON local_authority."tmp_All_Data" USING gist
    (geom)
    TABLESPACE pg_default;

-- Insert all data

INSERT INTO local_authority."tmp_All_Data"(
	geom, order_type, un_id, street_nam, zone, "locationNu", bays, "ospId", ohsets, ohsets_description, tarsets, tarsets_description, excset, excset_description, exeset, exeset_description)
SELECT geom, order_type, un_id, street_nam, zone, "locationNu", bays, "ospId", ohsets, ohsets_description, tarsets, tarsets_description, excset, excset_description, exeset, exeset_description
	FROM local_authority."LordshipLane";

INSERT INTO local_authority."tmp_All_Data"(
	geom, order_type, un_id, street_nam, zone, "locationNu", bays, "ospId", ohsets, ohsets_description, tarsets, tarsets_description, excset, excset_description, exeset, exeset_description)
SELECT geom, order_type, un_id, street_nam, zone, "locationNu", bays, "ospId", ohsets, ohsets_description, tarsets, tarsets_description, excset, excset_description, exeset, exeset_description
	FROM local_authority."StAnnesRoad";

-- Add necessary fields

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "GeometryID" character varying COLLATE pg_catalog."default";

UPDATE local_authority."tmp_All_Data"
SET "GeometryID" = id;

ALTER TABLE local_authority."tmp_All_Data"
    RENAME COLUMN "order_type" TO "RestrictionTypeDescription";

ALTER TABLE local_authority."tmp_All_Data"
    RENAME COLUMN "street_nam" TO "RoadName";

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "RestrictionTypeID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "GeomShapeID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "AzimuthToRoadCentreLine" integer;

ALTER TABLE local_authority."tmp_All_Data"
    RENAME COLUMN "ohsets_description" TO "TimePeriodDescription";

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "TimePeriodID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "MaxStayID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "NoReturnID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "MatchDayTimePeriodID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "NoWaitingTimeID" integer;

ALTER TABLE local_authority."tmp_All_Data"
    ADD COLUMN "NoLoadingTimeID" integer;

-- Generate lookup tables

-- DROP TABLE IF EXISTS local_authority."tmp_RestrictionType_Lookup" CASCADE;

CREATE TABLE local_authority."tmp_RestrictionType_Lookup"
(
    id SERIAL,
    "RestrictionTypeDescription" character varying COLLATE pg_catalog."default",
    "RestrictionTypeID" integer,
     CONSTRAINT "tmp_RestrictionType_Lookup_pkey" PRIMARY KEY (id)
);

INSERT INTO local_authority."tmp_RestrictionType_Lookup" ("RestrictionTypeDescription")
SELECT DISTINCT "RestrictionTypeDescription"
FROM local_authority."tmp_All_Data";

-- DROP TABLE IF EXISTS local_authority."tmp_TimePeriods_Lookup" CASCADE;

CREATE TABLE local_authority."tmp_TimePeriods_Lookup"
(
    id SERIAL,
    "tmp_TimePeriodDescription" character varying COLLATE pg_catalog."default",
    "TimePeriodDescription" character varying COLLATE pg_catalog."default",
    "TimePeriodID" integer,
    "MaxStayDescription" character varying COLLATE pg_catalog."default",
    "MaxStayID" integer,
    "NoReturnDescription" character varying COLLATE pg_catalog."default",
    "NoReturnID" integer,
    "MatchDayTimePeriodDescription" character varying COLLATE pg_catalog."default",
    "MatchDayTimePeriodID" integer,
    "NoWaitingTimePeriodDescription" character varying COLLATE pg_catalog."default",
    "NoWaitingTimeID" integer,
    "NoLoadingTimePeriodDescription" character varying COLLATE pg_catalog."default",
    "NoLoadingTimeID" integer,
    CONSTRAINT "tmp_TimePeriods_Lookup_pkey" PRIMARY KEY (id)
);

INSERT INTO local_authority."tmp_TimePeriods_Lookup" ("tmp_TimePeriodDescription")
SELECT DISTINCT "TimePeriodDescription"
FROM local_authority."tmp_All_Data";


