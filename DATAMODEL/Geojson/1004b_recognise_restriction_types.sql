-- For Southwark

/***
 Set up lookup tables
 ***/

DROP TABLE IF EXISTS import_geojson."RestrictionTypes_Lookup" CASCADE;

CREATE TABLE IF NOT EXISTS import_geojson."RestrictionTypes_Lookup"
(
    id SERIAL,
	"geojson_restriction_type_code" character varying(50) COLLATE pg_catalog."default",
    "geojson_restriction_type_name" character varying(50) COLLATE pg_catalog."default",
    "BayLineTypeCode" integer
)

TABLESPACE pg_default;

ALTER TABLE import_geojson."RestrictionTypes_Lookup"
    OWNER to postgres;

ALTER TABLE import_geojson."RestrictionTypes_Lookup"
    ADD PRIMARY KEY (id);

INSERT INTO import_geojson."RestrictionTypes_Lookup"(
	"geojson_restriction_type_code", "geojson_restriction_type_name")
SELECT DISTINCT "Restriction_type_codes", "Restriction_type_names"
FROM import_geojson."Southwark_single_geom";

UPDATE import_geojson."RestrictionTypes_Lookup" As p
	SET "BayLineTypeCode" = l."Code"
	FROM toms_lookups."BayLineTypes" l
	WHERE UPPER(p."geojson_restriction_type_name") = UPPER(l."Description");

UPDATE import_geojson."RestrictionTypes_Lookup" l
SET "geojson_restriction_type_code" = r."Restriction_type_codes"
FROM import_geojson."Southwark_single_geom" r
WHERE l."geojson_restriction_type_name" = r."Restriction_type_names";


 ... manual update of values ...
 
UPDATE import_geojson."Merged_Bays" As p
	SET "RestrictionTypeID"=l."BayLineTypeCode"
	FROM import_geojson."RestrictionTypes_Lookup" l
	WHERE l."geojson_restriction_type_code" = p."Restriction_type_codes";
	
UPDATE import_geojson."Merged_Lines" As p
	SET "RestrictionTypeID"=l."BayLineTypeCode"
	FROM import_geojson."RestrictionTypes_Lookup" l
	WHERE l."geojson_restriction_type_code" = p."Restriction_type_codes";

--

UPDATE import_geojson."Merged_Bays"
SET "NrBays" = "Bays"
WHERE "RestrictionTypeID" NOT IN (101, 109, 114, 117, 118, 119, 120, 121, 122, 125, 126, 127, 128, 129, 131, 133, 134, 135, 140, 141, 142);

UPDATE import_geojson."Merged_Bays"
SET "NrBays" = -1
WHERE "RestrictionTypeID" IN (101, 109, 114, 117, 118, 119, 120, 121, 122, 125, 126, 127, 128, 129, 131, 133, 134, 135, 140, 141, 142);
