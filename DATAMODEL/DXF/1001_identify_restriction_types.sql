-- dealing with DXF import for Haringey ...
/***

DXF imported directly into QGIS (opened from browser and not using import tool). Used polyline layer ... (although some details in polygon ...)

Data includes all OS mapping across the area - and data is tiled. Need to get details within the area of interest - remove details not intersecting polygon including setting CRS ...

Imported as multiline using ExportToPostgresql from Processing

Details are held against "Layer" field


***/

DROP TABLE IF EXISTS local_authority."DXF_Merged_single" CASCADE;

CREATE TABLE local_authority."DXF_Merged_single"
(
    id SERIAL,
    "Layer" character varying COLLATE pg_catalog."default",
    "GeomShapeID" integer,
    "AzimuthToRoadCentreLine" double precision,
    geom geometry(LineString,27700),
    CONSTRAINT dxf_merged_single_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

-- DROP INDEX local_authority.fp_geom_geom_idx;

CREATE INDEX dxf_merged_single_geom_idx
    ON local_authority."DXF_Merged_single" USING gist
    (geom)
    TABLESPACE pg_default;

INSERT INTO local_authority."DXF_Merged_single" ("Layer", geom)
SELECT layer AS "Layer", (ST_Dump(geom)).geom As geom
FROM local_authority."import_all";

-- Remove any duplicates

DELETE FROM local_authority."DXF_Merged_single" a
WHERE id NOT IN (
SELECT MAX(id)
FROM local_authority."DXF_Merged_single" r1
GROUP BY ST_AsBinary(geom), "Layer"
	);

-- Add GeometryID

ALTER TABLE local_authority."DXF_Merged_single"
    ADD COLUMN "GeometryID" integer;

UPDATE local_authority."DXF_Merged_single"
SET "GeometryID" = id;

-- start by identifying relevant items

ALTER TABLE local_authority."DXF_Merged_single"
    ADD COLUMN "RestrictionTypeID" integer;

-- Bay types

UPDATE local_authority."DXF_Merged_single"
SET "RestrictionTypeID" =
    CASE  WHEN "Layer" = 'Bays - Resident Permit Only' OR "Layer" = 'Hatch - Residents & Visitors'
                OR "Layer" = '0 - Prop Permit Parking Bay'
                 OR "Layer" = '_LBR_EX Res Bays'
                THEN 101
            WHEN "Layer" = '0 - Prop Resident Parking Bay' OR "Layer" = '1-Proposed Residents'' Bay'
                THEN 101

          WHEN "Layer" = 'Bays - Business Permit Only' OR "Layer" = 'Hatch - Business Use' THEN 102

          WHEN "Layer" = 'Bays - Pay and Display only' OR "Layer" = '10 - Hatch - Permit + 2hrs PBP bays'
                OR "Layer" = '10 - Hatch Permit holders + 5 hrs PBP bays' OR "Layer" = 'Hatch - Pay & Display'
                OR "Layer" = '_LBR_EX P&D only'
                THEN 103

          WHEN "Layer" = '0 - Prop Pay By Phone Bays'  THEN 103

          WHEN "Layer" = '0 - Existing shared use loading and permit bay' OR "Layer" = 'Hatch - Shared Use'
                OR "Layer" = '_LBR_Shared use BAY' OR "Layer" = '_LBR_EXISTING PERM PD BAY'
                THEN 105

          WHEN "Layer" = '0 - Prop Parking Bay Shared Parking' OR "Layer" = '1-Proposed Shared Use bay' THEN 105

          WHEN "Layer" = 'Bays - Permit Only' OR "Layer" = 'CPZ Permit bays (Business + Residents)' OR "Layer" = 'Ex Permit Holder Bay'
                OR "Layer" = '10 - Hatch - Permits Only' OR "Layer" = 'Hatch - Permits Only'
                OR "Layer" = '_LBR_EX PERM BAY' OR "Layer" = '_LBR_ST 171 Ice cream van Bay'
                THEN 131

          WHEN "Layer" = '0 - Prop Permit Parking Bay'  THEN 131

          WHEN "Layer" = 'Bays - Shared Use Permit holders + Pay and Display' OR "Layer" = '10 - Hatch - Permit + 2hrs PBP bays'
                OR "Layer" = '10 - Hatch Permit holders + 5 hrs PBP bays' OR "Layer" = 'Hatch - Permits only & Pay Display'
                OR "Layer" = 'Hatch Permit holders + Pay bay phone' OR "Layer" = '_sys_Permit holder or pay and display'
                THEN 134

          WHEN "Layer" = 'Bays - Shared-use Resident + Pay Display' THEN 135

          WHEN "Layer" = 'Bus Cage' OR "Layer" = 'Existing Bus Stop' OR "Layer" = '0 - Existing Bus Stops'
                OR "Layer" = '0 - Existing bus stop' OR "Layer" = '0-Existing Bus Stops'
                OR "Layer" = '_LBR_EX BUS BAY' OR "Layer" = 'LBRBUS'
                THEN 107

          WHEN "Layer" = 'Bays - Car Club Only' OR "Layer" = '0 - Existing Car Club' OR "Layer" = '10 - Hatch - Car Club bay' OR "Layer" = 'Hatch - Car Club bay'
                OR "Layer" = '_LBR_Car Club Bay'
                THEN 108

          WHEN "Layer" = '0 - Proposed Car Club Parking Bay'  THEN 108

          WHEN "Layer" = 'Bays - Disabled Permit Only' OR "Layer" = '0 - Existing Disabled Bays'
                OR "Layer" = '0-Existing Disabled Bay' OR "Layer" = '10 - Hatch - Disabled Use' OR "Layer" = 'Hatch - Disabled Use'
                OR "Layer" = '_LBR_Disabled Bay'
                THEN 110

          WHEN "Layer" = '0 - Proposed Disabled Bay' OR "Layer" = '0 - Prop Parking Bay_Disabled' THEN 110

          WHEN "Layer" = 'Bays - Doctors Permit Only' THEN 113

          WHEN "Layer" = '0 - Prop Parking Bay_Doctor' THEN 113

          WHEN "Layer" = 'Bays - Loading Only' OR "Layer" = 'CPZ Loading Bay BMG' OR "Layer" = 'Hatch - Loading Use'
                OR "Layer" = '_LBR_LOADING BAY' OR "Layer" = '_sys_new loading bay'
                THEN 114

          WHEN "Layer" = '0 - Prop Parking Bay_Loading bay'  THEN 114

          WHEN "Layer" = '0 - Proposed Motorcycles Bay' THEN 117

          WHEN "Layer" = '_LBR_M-C BAY' THEN 117

          WHEN "Layer" = 'Bays - Police Vehicles Only' OR "Layer" = 'Hatch - Police Use' THEN 120

          WHEN "Layer" = 'Hatch - 4hrs Free' OR "Layer" = 'Hatch - Stop and Shop high Road'
                OR "Layer" = '_LBR_SHORT STAY'
                THEN 126

          WHEN "Layer" = '0 - Ex Electric Vehicle Parking Bay' THEN 124

          WHEN "Layer" = '10 - Hatch - Red Route Short Stay' THEN 142

          WHEN "Layer" = '0 - Existing Bikehanger' THEN 147

     END
WHERE "RestrictionTypeID" IS NULL;

-- **** Line types

UPDATE local_authority."DXF_Merged_single"
SET "RestrictionTypeID" =
    CASE
        WHEN "Layer" = '0 - Existing Yellow Lines' OR "Layer" = '0 - Existing yellow lines' OR "Layer" = 'PR-RDMARK-YELLOW'
            OR "Layer" = '0 - Proposed Yellow Line' OR "Layer" = 'Ex Waiting Restrictions'
            THEN 201

        WHEN "Layer" = 'WR single yellow'
                OR "Layer" = '_EX SYL'
                THEN 201

        WHEN "Layer" = 'WR double yellow' OR
                "Layer" = '_PR DYL' OR "Layer" = '_EX DYL'
                THEN 202

        WHEN "Layer" = '0 - Existing SCH keep clear markings' OR "Layer" = '0 - Existing School Keep Clear'
                OR "Layer" = '_School Keep Clear'
                THEN 203

        WHEN "Layer" = 'Zebra' OR "Layer" = '0 - Existing Crossing' THEN 209

        WHEN "Layer" = 'Red Route' OR "Layer" = '0 - Existing Red Route Lines' OR "Layer" = 'PR-RDMARK-RED'
            THEN 217

        WHEN "Layer" = '7 - Private Road' OR "Layer" = 'Homes for Haringey Owned' OR "Layer" = '9 - Private Road'
                THEN 219

     END
WHERE "RestrictionTypeID" IS NULL;


-- Now check for parallel lines

-- DYLs
UPDATE local_authority."DXF_Merged_single" a
SET "RestrictionTypeID" = 202
WHERE id IN (
SELECT r2.id AS id
FROM local_authority."DXF_Merged_single" r1, local_authority."DXF_Merged_single" r2
WHERE r1.id != r2.id
AND st_within(r1.geom, ST_Buffer(r2.geom, 0.5)) -- 'endcap=flat' seems to miss some DYLs
AND (r1."Layer" = '0 - Existing Yellow Lines' OR r1."Layer" = '0 - Existing yellow lines' OR r1."Layer" = 'PR-RDMARK-YELLOW'
        OR r1."Layer" = '0 - Proposed Yellow Line' OR r1."Layer" = 'Ex Waiting Restrictions')
AND r1."Layer" = r2."Layer"
AND ST_Length(r1.geom) <= ST_Length(r2.geom)
ORDER BY r1.id );

DELETE FROM local_authority."DXF_Merged_single" a
WHERE id IN (
SELECT r1.id AS id
FROM local_authority."DXF_Merged_single" r1, local_authority."DXF_Merged_single" r2
WHERE r1.id != r2.id
AND st_within(r1.geom, ST_Buffer(r2.geom, 0.5))
AND (r1."Layer" = '0 - Existing Yellow Lines' OR r1."Layer" = '0 - Existing yellow lines' OR r1."Layer" = 'PR-RDMARK-YELLOW'
        OR r1."Layer" = '0 - Proposed Yellow Line' OR r1."Layer" = 'Ex Waiting Restrictions')
AND r1."Layer" = r2."Layer"
AND ST_Length(r1.geom) <= ST_Length(r2.geom)
ORDER BY r1.id );


-- DRLs
UPDATE local_authority."DXF_Merged_single" a
SET "RestrictionTypeID" = 218
WHERE id IN (
SELECT r2.id AS id
FROM local_authority."DXF_Merged_single" r1, local_authority."DXF_Merged_single" r2
WHERE r1.id != r2.id
AND st_within(r1.geom, ST_Buffer(r2.geom, 0.5))
AND (r1."Layer" = 'Red Route' OR r1."Layer" = '0 - Existing Red Route Lines' OR r1."Layer" = 'PR-RDMARK-RED')
AND r1."Layer" = r2."Layer"
AND ST_Length(r1.geom) <= ST_Length(r2.geom)
ORDER BY r1.id );

DELETE FROM local_authority."DXF_Merged_single" a
WHERE id IN (
SELECT r1.id AS id
FROM local_authority."DXF_Merged_single" r1, local_authority."DXF_Merged_single" r2
WHERE r1.id != r2.id
AND st_within(r1.geom, ST_Buffer(r2.geom, 0.5))
AND (r1."Layer" = 'Red Route' OR r1."Layer" = '0 - Existing Red Route Lines' OR r1."Layer" = 'PR-RDMARK-RED')
AND r1."Layer" = r2."Layer"
AND ST_Length(r1.geom) <= ST_Length(r2.geom)
ORDER BY r1.id );

-- Just generally check for parallel lines

DELETE FROM local_authority."DXF_Merged_single" a
WHERE id IN (
SELECT r1.id AS id
FROM local_authority."DXF_Merged_single" r1, local_authority."DXF_Merged_single" r2
WHERE r1.id != r2.id
AND st_within(r1.geom, ST_Buffer(r2.geom, 0.5))
AND r1."Layer" = r2."Layer"
AND ST_Length(r1.geom) <= ST_Length(r2.geom)
ORDER BY r1.id );


--- *** TIDY UP
DELETE FROM local_authority."DXF_Merged_single"
WHERE "RestrictionTypeID" IS NULL;
