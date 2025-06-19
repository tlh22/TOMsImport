/***
 * Change to single geometry with standard name
 *
 ***/
 
ALTER TABLE IF EXISTS import_geojson."bermondsey parking restrictions" RENAME TO "Parking_Restrictions_27700";  -- *** Will need to change name of table

DROP TABLE IF EXISTS import_geojson."Southwark_single_geom" CASCADE;

DROP SEQUENCE IF EXISTS import_geojson."Southwark_single_geom_id_seq";

CREATE SEQUENCE IF NOT EXISTS import_geojson."Southwark_single_geom_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

CREATE TABLE IF NOT EXISTS import_geojson."Southwark_single_geom"
(
    id integer NOT NULL DEFAULT nextval('import_geojson."Southwark_single_geom_id_seq"'::regclass),
    geom geometry(Polygon,27700),
    "Zone_type" character varying COLLATE pg_catalog."default",
    "Zone_name" character varying COLLATE pg_catalog."default",
    "Street_name" character varying COLLATE pg_catalog."default",
    "Restriction_type_codes" character varying COLLATE pg_catalog."default",
    "Restriction_type_names" character varying COLLATE pg_catalog."default",
    "Parking_code" character varying COLLATE pg_catalog."default",
    "Bays" integer,
    "Entitlements" character varying COLLATE pg_catalog."default",
    "Operating_hours" character varying COLLATE pg_catalog."default",
    "Exceptions" character varying COLLATE pg_catalog."default",
    "Tariffs" character varying COLLATE pg_catalog."default",
    "Note" character varying COLLATE pg_catalog."default",
    CONSTRAINT "Southwark_single_geo_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS import_geojson."Southwark_single_geom"
    OWNER to postgres;

--

INSERT INTO import_geojson."Southwark_single_geom"(
	"Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note",
	geom)
SELECT Zone_type, Zone_name, Street_name, Restriction_type_codes, Restriction_type_names, Parking_code, Bays, Entitlements, Operating_hours, Exceptions, Tariffs, Note,
	(ST_DUMP(wkb_geometry)).geom AS geom
	FROM import_geojson."Parking_Restrictions_27700";

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
FROM import_geojson."Parking_Restrictions_27700";

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
    CONSTRAINT "TimePeriods_Transfer_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS import_geojson."TimePeriods_Transfer"
    OWNER to postgres;
	
-- Populate

INSERT INTO import_geojson."TimePeriods_Transfer"(
	operating_hours, exceptions)
SELECT DISTINCT operating_hours, exceptions
FROM import_geojson."Parking_Restrictions_27700";

/***

Now add lookup details manually ...

***/
