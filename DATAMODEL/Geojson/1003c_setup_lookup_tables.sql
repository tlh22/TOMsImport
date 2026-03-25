/***

set up lookup tables

***/

-- DROP TABLE IF EXISTS import_geojson."RestrictionTypes_Lookup";

CREATE TABLE IF NOT EXISTS import_geojson."RestrictionTypes_Lookup"
(
    id SERIAL,
    geojson_restriction_type_code character varying(50) COLLATE pg_catalog."default",
    geojson_restriction_type_name character varying(50) COLLATE pg_catalog."default",
    "BayLineTypeCode" integer,
    CONSTRAINT "RestrictionTypes_Lookup_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS import_geojson."RestrictionTypes_Lookup"
    OWNER to postgres;

-- Populate

INSERT INTO import_geojson."RestrictionTypes_Lookup"(
	geojson_restriction_type_code, geojson_restriction_type_name)
SELECT DISTINCT restriction_type_codes, restriction_type_names
FROM import_geojson."Parking_Restrictions_Polygon" i
WHERE NOT EXISTS (
	SELECT 1 FROM import_geojson."RestrictionTypes_Lookup" t
	WHERE i.restriction_type_codes = t.geojson_restriction_type_code
	AND i.restriction_type_names = t.geojson_restriction_type_name)
;

UPDATE import_geojson."RestrictionTypes_Lookup" As p
	SET "BayLineTypeCode" = l."Code"
	FROM toms_lookups."BayLineTypes" l
	WHERE UPPER(p."geojson_restriction_type_name") = UPPER(l."Description");
	
-- DROP TABLE IF EXISTS import_geojson."TimePeriods_Transfer";

CREATE TABLE IF NOT EXISTS import_geojson."TimePeriods_Transfer"
(
    id SERIAL,
    operating_hours character varying COLLATE pg_catalog."default",
	exceptions character varying COLLATE pg_catalog."default",
    "TimePeriodDescription" character varying(254) COLLATE pg_catalog."default",
    "AdditionalConditionDescription" character varying(254) COLLATE pg_catalog."default",
    "TimePeriodCode" integer,
    "AdditionalConditionCode" integer,
    "MaxStayID" integer,
    "NoReturnID" integer,
    "NoLoadingTimeID" integer,
    CONSTRAINT "TimePeriods_Transfer_pkey" PRIMARY KEY (id),
	UNIQUE (operating_hours, exceptions)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS import_geojson."TimePeriods_Transfer"
    OWNER to postgres;
	
-- Populate

INSERT INTO import_geojson."TimePeriods_Transfer"(
	operating_hours, exceptions)
SELECT DISTINCT operating_hours, exceptions
FROM import_geojson."Parking_Restrictions_Polygon" i
WHERE NOT EXISTS (
	SELECT 1 FROM import_geojson."TimePeriods_Transfer" t
	WHERE i.operating_hours = t.operating_hours
	AND i.exceptions = t.exceptions);
	
/***

Now add lookup details manually ...

***/

