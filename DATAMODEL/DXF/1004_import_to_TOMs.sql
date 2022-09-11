/***
Now import into structure
***/

-- Split into different tables




INSERT INTO toms."Bays"(
	"RestrictionID", geom, "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "TimePeriodID")
SELECT uuid_generate_v4(), geom, "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", 1
	FROM local_authority."DXF_Merged_single"
	WHERE "RestrictionTypeID" < 200
	--AND "CPZ" IN ('7S', '7 Sisters South 2')
	;

INSERT INTO toms."Lines"(
	"RestrictionID", geom, "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", "NoWaitingTimeID")
SELECT uuid_generate_v4(), geom, "RestrictionTypeID", "GeomShapeID", "AzimuthToRoadCentreLine", 1
	FROM local_authority."DXF_Merged_single"
	WHERE "RestrictionTypeID" > 200
	--AND "CPZ" IN ('7S', '7 Sisters South 2')
	;

-- Crossovers

INSERT INTO highway_assets."CrossingPoints"(
	"RestrictionID", geom, "CrossingPointTypeID", "GeomShapeID", "AzimuthToRoadCentreLine")
SELECT uuid_generate_v4(), geom, 3, 35, "AzimuthToRoadCentreLine"
	FROM local_authority."DXF_DroppedKerbs_single2"
	;