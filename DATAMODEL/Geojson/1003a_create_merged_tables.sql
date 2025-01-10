/***
 * Populate tables

 ***/
 
CREATE TABLE import_geojson."Merged_Lines"
AS 
SELECT * FROM import_geojson.eastcamberwell_restrictions
WHERE  "Restriction_type_codes" IN ( 'DYL' ,  'DYL, DYKM' ,  'DYL, SYKM' ,  'SYL' ,  'SYL, SYKM' ,  'ASKCL' );

CREATE TABLE import_geojson."Merged_Bays"
AS 
SELECT * FROM import_geojson.eastcamberwell_restrictions
WHERE  "Restriction_type_codes" NOT IN ( 'DYL' ,  'DYL, DYKM' ,  'DYL, SYKM' ,  'SYL' ,  'SYL, SYKM' ,  'ASKCL' );

/***
 Set up lookup tables
 ***/

DROP TABLE IF EXISTS import_geojson."RestrictionTypes_Lookup";

CREATE TABLE IF NOT EXISTS import_geojson."RestrictionTypes_Lookup"
(
    id SERIAL,
	"geojson_restriction_type_codes" character varying(50) COLLATE pg_catalog."default",
    "geojson_restriction_type_names" character varying(50) COLLATE pg_catalog."default",
    "BayLineTypeCode" integer
)

TABLESPACE pg_default;

ALTER TABLE import_geojson."RestrictionTypes_Lookup"
    OWNER to postgres;

ALTER TABLE import_geojson."RestrictionTypes_Lookup"
    ADD PRIMARY KEY (id);

INSERT INTO import_geojson."RestrictionTypes_Lookup"(
	"geojson_restriction_type")
SELECT DISTINCT "Restriction_type_codes", "Restriction_type_names"
FROM import_geojson.eastcamberwell_restrictions;

UPDATE import_geojson."RestrictionTypes_Lookup" As p
	SET "BayLineTypeCode" = l."Code"
	FROM toms_lookups."BayLineTypes" l
	WHERE UPPER(p."geojson_restriction_type") = UPPER(l."Description");



UPDATE import_geojson."RestrictionTypes_Lookup" l
SET "geojson_restriction_type_codes" = l."Restriction_type_codes"
FROM import_geojson.eastcamberwell_restrictions r
WHERE l."geojson_restriction_type_names" = r."Restriction_type_names"

/***
 * Now add GeometryID, etc

 ***/

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Lines"
SET "GeometryID" = id;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "RestrictionTypeID" integer;
	
UPDATE import_geojson."Merged_Lines" r
SET "RestrictionTypeID" = l."BayLineTypeCode"
FROM import_geojson."RestrictionTypes_Lookup" l
WHERE l."geojson_restriction_type_names" = r."Restriction_type_names";

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "GeomShapeID" integer;
	
UPDATE import_geojson."Merged_Lines"
SET "GeomShapeID" = 10;

UPDATE import_geojson."Merged_Lines"
SET "GeomShapeID" = 12
WHERE "RestrictionTypeID" = 203;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "AzimuthToRoadCentreLine" double precision;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "NoWaitingTimeID" integer;

ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "NoLoadingTimeID" integer;
	
ALTER TABLE import_geojson."Merged_Lines"
    ADD COLUMN "CPZ" character varying(40) COLLATE pg_catalog."default";

UPDATE import_geojson."Merged_Lines"
SET "CPZ" = "Zone_name";

--

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN "GeometryID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeometryID" = id;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "RestrictionTypeID" integer;

UPDATE import_geojson."Merged_Bays" r
SET "RestrictionTypeID" = l."BayLineTypeCode"
FROM import_geojson."RestrictionTypes_Lookup" l
WHERE l."geojson_restriction_type_names" = r."Restriction_type_names";

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "GeomShapeID" integer;

UPDATE import_geojson."Merged_Bays"
SET "GeomShapeID" = 21;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "AzimuthToRoadCentreLine" double precision;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "NrBays" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "TimePeriodID" integer;

ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "MaxStayID" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "NoReturnID" integer;
	
ALTER TABLE import_geojson."Merged_Bays"
    ADD COLUMN IF NOT EXISTS "CPZ" character varying(40) COLLATE pg_catalog."default";
	
UPDATE import_geojson."Merged_Bays"
SET "CPZ" = "Zone_name";
