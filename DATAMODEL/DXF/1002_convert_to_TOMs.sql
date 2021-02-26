/***

Now start to deal with structure - and then snap vertices ...


***/

-- remove any details that are not required.
DELETE FROM local_authority."DXF_Merged_single"
WHERE "RestrictionTypeID" IS NULL;

-- add fields

ALTER TABLE local_authority."DXF_Merged_single"
    ADD COLUMN "GeomShapeID" integer;
ALTER TABLE local_authority."DXF_Merged_single"
    ADD COLUMN "AzimuthToRoadCentreLine" double precision;
ALTER TABLE local_authority."DXF_Merged_single"
    ADD COLUMN "RestrictionID" character varying(254);
ALTER TABLE local_authority."DXF_Merged_single"
    ADD COLUMN "CPZ" character varying(40);

-- Bays
UPDATE local_authority."DXF_Merged_single"
SET "GeomShapeID" = 1
WHERE "RestrictionTypeID" < 200;

-- Check for off-carriageway bays
UPDATE local_authority."DXF_Merged_single" AS r
SET "GeomShapeID" = 3
FROM topography."RC_Polygons" p
WHERE NOT ST_Within(r.geom, p.geom)
AND "GeomShapeID" = 1;

-- Lines
UPDATE local_authority."DXF_Merged_single"
SET "GeomShapeID" = 10
WHERE "RestrictionTypeID" > 200;

-- RestrictionID
UPDATE local_authority."DXF_Merged_single"
SET "RestrictionID" = uuid_generate_v4()
WHERE "RestrictionID" IS NULL;

-- CPZ
UPDATE local_authority."DXF_Merged_single" AS r
SET "CPZ" = c."CPZ"
FROM mhtc_operations."CPZs_ToBeSurveyed" c
WHERE ST_Intersects(r.geom, c.geom)
AND r."CPZ" IS NULL;

-- Az
UPDATE local_authority."DXF_Merged_single" AS c
SET "AzimuthToRoadCentreLine" = ST_Azimuth(ST_LineInterpolatePoint(c.geom, 0.5), closest.geom)
FROM (SELECT DISTINCT ON (s."id") s."id" AS id, ST_ClosestPoint(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS geom,
        ST_Distance(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS length
      FROM "highways_network"."roadlink" cl, local_authority."DXF_Merged_single" s
      ORDER BY s."id", length) AS closest
WHERE c."id" = closest.id;   --- *** TODO: Check that this is best option for Az