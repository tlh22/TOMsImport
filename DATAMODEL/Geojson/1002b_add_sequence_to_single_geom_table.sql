/***
 * For some reason the SRID is not coming through correctly. Re-project to 27700

 ***/

DROP SEQUENCE IF EXISTS import_geojson."Southwark_single_geom_id_seq";

CREATE SEQUENCE IF NOT EXISTS import_geojson."Southwark_single_geom_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE import_geojson."Southwark_single_geom_id_seq"
    OWNED BY import_geojson."Southwark_single_geom".id;

ALTER SEQUENCE import_geojson."Southwark_single_geom_id_seq"
    OWNER TO postgres;

ALTER TABLE import_geojson."Southwark_single_geom" ALTER COLUMN "id" SET DEFAULT nextval('import_geojson."Southwark_single_geom_id_seq"'::regclass);

--

INSERT INTO import_geojson."Southwark_single_geom"(
	"Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note",
	geom)
SELECT "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note",
	(ST_DUMP(geom)).geom AS geom
	FROM import_geojson."Parking_Restrictions_27700";
