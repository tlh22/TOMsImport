-- create copy of table but change geometry type to linestring

DROP TABLE IF EXISTS import_geojson."Merged_Bays_LineString" CASCADE;

CREATE TABLE import_geojson."Merged_Bays_LineString" AS
    TABLE import_geojson."Merged_Bays"
    WITH NO DATA;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays_LineString"
    ADD PRIMARY KEY (id);

ALTER TABLE import_geojson."Merged_Bays_LineString" ALTER COLUMN geom type geometry(LineString, 27700);

DROP SEQUENCE IF EXISTS import_geojson."Merged_Bays_LineString_id_seq";

CREATE SEQUENCE IF NOT EXISTS import_geojson."Merged_Bays_LineString_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE import_geojson."Merged_Bays_LineString_id_seq"
    OWNED BY import_geojson."Merged_Bays_LineString".id;

ALTER SEQUENCE import_geojson."Merged_Bays_LineString_id_seq"
    OWNER TO postgres;

ALTER TABLE import_geojson."Merged_Bays_LineString" ALTER COLUMN "id" SET DEFAULT nextval('import_geojson."Merged_Bays_LineString_id_seq"'::regclass);

--

DROP TABLE IF EXISTS import_geojson."Merged_Lines_LineString" CASCADE;

CREATE TABLE import_geojson."Merged_Lines_LineString" AS
    TABLE import_geojson."Merged_Lines"
    WITH NO DATA;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines_LineString"
    ADD PRIMARY KEY (id);

ALTER TABLE import_geojson."Merged_Lines_LineString" ALTER COLUMN geom type geometry(LineString, 27700);

DROP SEQUENCE IF EXISTS import_geojson."Merged_Lines_LineString_id_seq";

CREATE SEQUENCE IF NOT EXISTS import_geojson."Merged_Lines_LineString_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE import_geojson."Merged_Lines_LineString_id_seq"
    OWNED BY import_geojson."Merged_Lines_LineString".id;

ALTER SEQUENCE import_geojson."Merged_Lines_LineString_id_seq"
    OWNER TO postgres;

ALTER TABLE import_geojson."Merged_Lines_LineString" ALTER COLUMN "id" SET DEFAULT nextval('import_geojson."Merged_Lines_LineString_id_seq"'::regclass);


/***

INSERT INTO import_geojson."Merged_Bays_LineString"(
	gid, geom, ogc_fid, ambulance_bay, id, traffic_engineers, parking_control, permitted_parking, type, boundary_type, lengthm, location, reference_number, lbe_code, hours_of_operation, enforcement_level, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID")
SELECT gid, ST_ExteriorRing(geom), ogc_fid, ambulance_bay, id, traffic_engineers, parking_control, permitted_parking, type, boundary_type, lengthm, location, reference_number, lbe_code, hours_of_operation, enforcement_level, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID"
	FROM import_geojson."Merged_Bays";
***/

INSERT INTO import_geojson."Merged_Bays_LineString"(
geom, "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note", "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NrBays", "TimePeriodID", "MaxStayID", "NoReturnID", "CPZ"
)
SELECT ST_ExteriorRing(geom), "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note", "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NrBays", "TimePeriodID", "MaxStayID", "NoReturnID", "CPZ"
	FROM import_geojson."Merged_Bays";


--

INSERT INTO import_geojson."Merged_Lines_LineString"(
geom, "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note", "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID", "NoLoadingTimeID", "CPZ"
)
SELECT ST_ExteriorRing(geom), "Zone_type", "Zone_name", "Street_name", "Restriction_type_codes", "Restriction_type_names", "Parking_code", "Bays", "Entitlements", "Operating_hours", "Exceptions", "Tariffs", "Note", "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID", "NoLoadingTimeID", "CPZ"
	FROM import_geojson."Merged_Lines";

	
/***
 * Was able to use TOMs_Import to create LineStrings for bays from Polygons. Saved into db as Merged_Bays_LineString. There were some duplicates to be removed.
 ***/

DELETE FROM import_geojson."Merged_Bays_LineString" a
WHERE gid NOT IN (
SELECT MAX(gid)
FROM import_geojson."Merged_Bays_LineString" r1
GROUP BY ST_AsBinary(geom), "RestrictionTypeID"
	);

