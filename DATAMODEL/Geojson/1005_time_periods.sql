-- deal with the time periods

DROP TABLE IF EXISTS import_geojson."TimePeriods_Transfer";
CREATE TABLE import_geojson."TimePeriods_Transfer"
(
    id SERIAL,
    control_time_details character varying(254) COLLATE pg_catalog."default",
    "AdditionalConditionDescription" character varying(254) COLLATE pg_catalog."default",
    "TimePeriodCode" integer,
    "AdditionalConditionCode" integer,
	"MaxStayID" integer,
	"NoReturnTimeID" integer
)

TABLESPACE pg_default;

ALTER TABLE import_geojson."TimePeriods_Transfer"
    OWNER to postgres;

ALTER TABLE import_geojson."TimePeriods_Transfer"
    ADD PRIMARY KEY (id);

INSERT INTO import_geojson."TimePeriods_Transfer"(
	control_time_details)
SELECT DISTINCT operating_hours
FROM (SELECT operating_hours
     FROM import_geojson."Merged_Bays_selected"
     UNION
     SELECT operating_hours
     FROM import_geojson."Merged_Lines_selected") AS a;
	 
/***
DROP TABLE IF EXISTS "import_geojson"."TimePeriods_Transfer";
CREATE TABLE import_geojson."TimePeriods_Transfer"
(
    "Code" SERIAL,
    control_time_details character varying(254) COLLATE pg_catalog."default",
    "AdditionalConditionDescription" character varying(254) COLLATE pg_catalog."default",
    "TimePeriodCode" integer,
    "AdditionalConditionCode" integer,
	"MaxStayID" integer,
	"NoReturnID" integer
);

ALTER TABLE "import_geojson"."TimePeriods_Transfer" OWNER TO "postgres";

ALTER TABLE "import_geojson"."TimePeriods_Transfer"
    ADD PRIMARY KEY ("Code");

-- Now load

COPY "import_geojson"."TimePeriods_Transfer"("control_time_details", "AdditionalConditionDescription", "TimePeriodCode", "AdditionalConditionCode", "MaxStayID", "NoReturnID" )
FROM 'C:\Users\Public\Documents\TimePeriods_Transfer.csv'
DELIMITER ','
CSV HEADER;
***/


 ... manual update of values ...

UPDATE import_geojson."TimePeriods_Transfer" As p
	SET "TimePeriodCode"=l."Code"
	FROM toms_lookups."TimePeriods" l
	WHERE p."TimePeriodDescription" = l."Description"
    AND p."TimePeriodCode" IS NULL;

-- now update

UPDATE import_geojson."Merged_Bays_selected" As p
	SET "TimePeriodID"=l."TimePeriodCode", "MaxStayID"=l."MaxStayID", "NoReturnTimeID"=l."NoReturnTimeID"
	FROM import_geojson."TimePeriods_Transfer" l
	WHERE p.operating_hours = l.control_time_details;

UPDATE import_geojson."Merged_Lines_selected" As p
	SET "NoWaitingTimeID"=l."TimePeriodCode"
	FROM import_geojson."TimePeriods_Transfer" l
	WHERE p.operating_hours = l.control_time_details;