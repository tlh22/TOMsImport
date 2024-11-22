/***

Can use TOMsImport to bring in polygons. Need to change to be single rather than multi

***/


-- create copy of table but change geometry type to linestring

DROP TABLE IF EXISTS import_geojson."Merged_Bays_LineString";
CREATE TABLE import_geojson."Merged_Bays_LineString" AS
    TABLE import_geojson."Merged_Bays"
    WITH NO DATA;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays_LineString"
    ADD PRIMARY KEY (id);

ALTER TABLE import_geojson."Merged_Bays_LineString" ALTER COLUMN geom type geometry(LineString, 27700);

/***
INSERT INTO import_geojson."Merged_Bays_LineString"(
	gid, geom, ogc_fid, ambulance_bay, id, traffic_engineers, parking_control, permitted_parking, type, boundary_type, lengthm, location, reference_number, lbe_code, hours_of_operation, enforcement_level, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID")
SELECT gid, ST_ExteriorRing(geom), ogc_fid, ambulance_bay, id, traffic_engineers, parking_control, permitted_parking, type, boundary_type, lengthm, location, reference_number, lbe_code, hours_of_operation, enforcement_level, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID"
	FROM import_geojson."Merged_Bays";
***/

INSERT INTO import_geojson."Merged_Bays_LineString"(
	id, geom, ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, bays, entitlements, operating_hours, exceptions, note, tariffs, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID", "CPZ", "NoReturnTimeID", "MaxStayID")
SELECT id, ST_ExteriorRing(geom), ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, bays, entitlements, operating_hours, exceptions, note, tariffs, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID", "CPZ", "NoReturnTimeID", "MaxStayID"
	FROM import_geojson."Merged_Bays_selected";

--

DROP TABLE IF EXISTS import_geojson."Merged_Lines_LineString";
CREATE TABLE import_geojson."Merged_Lines_LineString" AS
    TABLE import_geojson."Merged_Lines"
    WITH NO DATA;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines_LineString"
    ADD PRIMARY KEY (id);

ALTER TABLE import_geojson."Merged_Lines_LineString" ALTER COLUMN geom type geometry(LineString, 27700);

INSERT INTO import_geojson."Merged_Lines_LineString"(
	id, geom, ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, entitlements, operating_hours, exceptions, note, bays, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID", "CPZ")
SELECT id, ST_ExteriorRing(geom), ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, entitlements, operating_hours, exceptions, note, bays, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID", "CPZ"
	FROM import_geojson."Merged_Lines_selected";


/***
 * Was able to use TOMs_Import to create LineStrings for bays from Polygons. Saved into db as Merged_Bays_LineString. There were some duplicates to be removed.
 ***/

DELETE FROM import_geojson."Merged_Bays_LineString" a
WHERE gid NOT IN (
SELECT MAX(gid)
FROM import_geojson."Merged_Bays_LineString" r1
GROUP BY ST_AsBinary(geom), "RestrictionTypeID"
	);

---

/***

Make single

***/

DROP TABLE IF EXISTS import_geojson."Merged_Bays_LineString_from_Import_Single";
CREATE TABLE import_geojson."Merged_Bays_LineString_from_Import_Single" AS
    TABLE import_geojson."Merged_Bays_LineString_from_Import"
    WITH NO DATA;

ALTER TABLE IF EXISTS import_geojson."Merged_Bays_LineString_from_Import_Single"
    ADD PRIMARY KEY (id);

ALTER TABLE IF EXISTS import_geojson."Merged_Bays_LineString_from_Import_Single" ALTER COLUMN geom type geometry(LineString, 27700);

INSERT INTO import_geojson."Merged_Bays_LineString_from_Import_Single"(
	id, geom, ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, bays, entitlements, operating_hours, exceptions, note, tariffs, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID", "CPZ", "NoReturnTimeID", "MaxStayID")
SELECT id, (ST_DUMP(geom)).geom::geometry(Linestring,27700) AS geom, ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, bays, entitlements, operating_hours, exceptions, note, tariffs, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID", "CPZ", "NoReturnTimeID", "MaxStayID"
	FROM import_geojson."Merged_Bays_LineString_from_Import";
	
--
	
DROP TABLE IF EXISTS import_geojson."Merged_Lines_LineString_from_Import_Single";
CREATE TABLE import_geojson."Merged_Lines_LineString_from_Import_Single" AS
    TABLE import_geojson."Merged_Lines_LineString_from_Import"
    WITH NO DATA;

ALTER TABLE IF EXISTS import_geojson."Merged_Lines_LineString_from_Import_Single"
    ADD PRIMARY KEY (id);

ALTER TABLE IF EXISTS import_geojson."Merged_Lines_LineString_from_Import_Single" ALTER COLUMN geom type geometry(LineString, 27700);

INSERT INTO import_geojson."Merged_Lines_LineString_from_Import_Single"(
	id, geom, ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, entitlements, operating_hours, exceptions, note, bays, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID", "CPZ")
SELECT id, (ST_DUMP(geom)).geom::geometry(Linestring,27700) AS geom, ogc_fid, zone_type, zone_name, street_name, restriction_type_codes, restriction_type_names, parking_code, entitlements, operating_hours, exceptions, note, bays, layer, path, "GeometryID", "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID", "CPZ"
	FROM import_geojson."Merged_Lines_LineString_from_Import";	
	
UPDATE import_geojson."Merged_Bays_LineString_from_Import_Single" AS r
SET "MaxStayID" = m."MaxStayID", "NoReturnTimeID" = m."NoReturnTimeID"
FROM "import_geojson"."Merged_Bays_selected" m
WHERE r."id" = m."id";