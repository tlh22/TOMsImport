-- deal with the time periods

CREATE TABLE import_geojson."TimePeriods_Transfer"
(
    id SERIAL,
    control_time_details character varying(254) COLLATE pg_catalog."default",
    "TimePeriodDescription" character varying(254) COLLATE pg_catalog."default",
    "AdditionalConditionDescription" character varying(254) COLLATE pg_catalog."default",
    "TimePeriodCode" integer,
    "AdditionalConditionCode" integer,
	"MaxStayID" integer,
	"NoReturnID" integer,
	"NoLoadingTimeID" integer
)

TABLESPACE pg_default;

ALTER TABLE import_geojson."TimePeriods_Transfer"
    OWNER to postgres;

ALTER TABLE import_geojson."TimePeriods_Transfer"
    ADD PRIMARY KEY (id);

INSERT INTO import_geojson."TimePeriods_Transfer"(
	control_time_details)
SELECT DISTINCT "Operating_hours"
FROM (SELECT "Operating_hours"
     FROM import_geojson."Merged_Bays"
     UNION
     SELECT "Operating_hours"
     FROM import_geojson."Merged_Lines") AS a;

UPDATE import_geojson."TimePeriods_Transfer"
SET "TimePeriodDescription" = control_time_details;


 ... manual update of values ...


-- now update

UPDATE import_geojson."Merged_Bays" As p
	SET "TimePeriodID"=l."TimePeriodCode", "MaxStayID"=l."MaxStayID", "NoReturnID"=l."NoReturnID"
	FROM import_geojson."TimePeriods_Transfer" l
	WHERE p."Operating_hours" = l.control_time_details;

UPDATE import_geojson."Merged_Lines" As p
	SET "NoWaitingTimeID"=l."TimePeriodCode", "NoLoadingTimeID"=l."NoLoadingTimeID"
	FROM import_geojson."TimePeriods_Transfer" l
	WHERE p."Operating_hours" = l.control_time_details;
	
-- Update TimePeriodsInUse

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

