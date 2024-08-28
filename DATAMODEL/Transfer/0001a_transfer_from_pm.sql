-- Table: local_authority.All Confirmed Orders_lines

-- DROP TABLE local_authority."PM_Lines_Transfer_Current";

CREATE TABLE local_authority."PM_Lines_Transfer_Current"
(
    id SERIAL,
    geom geometry(LineString,27700),

	item_ref double precision,
    "Order_type" character varying(50) COLLATE pg_catalog."default",
    "Street_nam" character varying(100) COLLATE pg_catalog."default",
    "Length" double precision,
    restrictio character varying(254) COLLATE pg_catalog."default",
    times_of_e character varying(254) COLLATE pg_catalog."default",
    "Ord_Title" character varying(254) COLLATE pg_catalog."default",
    "oCashless_" character varying(100) COLLATE pg_catalog."default",
    "oCar_Club_" character varying(32) COLLATE pg_catalog."default",
    "bOrganisat" character varying(100) COLLATE pg_catalog."default",
    "bTariff" character varying(25) COLLATE pg_catalog."default",
    "bPandDMach" double precision,
    "bEchelon" character varying(5) COLLATE pg_catalog."default",
    "bNoBays" double precision,
    "bLocation" character varying(6) COLLATE pg_catalog."default",
    "oCar_club1" character varying(15) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    OWNER to postgres;

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD PRIMARY KEY (id);

-- use a transfer table

/* Havering */
INSERT INTO local_authority."PM_Lines_Transfer_Current"(
	pmid, order_type, street_nam, side_of_ro, schedule, mr_schedul, nsg, zoneno, no_of_spac, echelon, times_of_e, geom)
SELECT pmid, order_type, street_nam, side_of_ro, schedule, mr_schedul, nsg, zoneno, no_of_spac, echelon, times_of_e, (ST_Dump(geom)).geom AS geom
FROM local_authority."All Confirmed Orders_lines"
WHERE date_to IS NULL;

/* RBKC
INSERT INTO local_authority."PM_Lines_Transfer_Current"(
	item_ref, "Order_type", "Street_nam", restrictio, times_of_e, "Ord_Title", "oCashless_", "oCar_Club_", "bOrganisat", "bTariff", "bPandDMach", "bEchelon", "bNoBays", "bLocation", "oCar_club1", geom)
SELECT item_ref, order_type, street_nam, restrictio, times_of_e, order_titl, cashless_p, car_club_o, organisati, tariff, pandd_mach, echelon_ba, number_of_, location_c, car_club_v, (ST_Dump(geom)).geom AS geom
FROM local_authority."Parking_Restrictions"
WHERE date_to IS NULL;
*/

-- deal with the restriction types

CREATE TABLE local_authority."PM_RestrictionTypes_Transfer"
(
    id SERIAL,
    "Order_type" character varying(50) COLLATE pg_catalog."default",
    BayLineTypeCode integer
)

TABLESPACE pg_default;

ALTER TABLE local_authority."PM_RestrictionTypes_Transfer"
    OWNER to postgres;

ALTER TABLE local_authority."PM_RestrictionTypes_Transfer"
    ADD PRIMARY KEY (id);

INSERT INTO local_authority."PM_RestrictionTypes_Transfer"(
	"Order_type")
SELECT DISTINCT "Order_type"
FROM local_authority."PM_Lines_Transfer_Current";

UPDATE local_authority."PM_RestrictionTypes_Transfer" As p
	SET baylinetypecode=l."Code"
	FROM toms_lookups."BayLineTypes" l
	WHERE p."Order_type" = l."Description";

-- Update TypesInUse

INSERT INTO toms_lookups."BayTypesInUse"(
	"Code", "GeomShapeGroupType")
SELECT DISTINCT baylinetypecode, 'LineString'
FROM local_authority."PM_RestrictionTypes_Transfer"
WHERE baylinetypecode < 200
AND baylinetypecode NOT IN (SELECT "Code"
	FROM toms_lookups."BayTypesInUse");

INSERT INTO toms_lookups."LineTypesInUse"(
	"Code", "GeomShapeGroupType")
SELECT DISTINCT baylinetypecode, 'LineString'
FROM local_authority."PM_RestrictionTypes_Transfer"
WHERE baylinetypecode > 200
AND baylinetypecode NOT IN (SELECT "Code"
	FROM toms_lookups."LineTypesInUse");

--

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "RestrictionTypeID" integer;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "RestrictionTypeID"=l.baylinetypecode
	FROM local_authority."PM_RestrictionTypes_Transfer" l
	WHERE p."Order_type" = l."Order_type";

-- deal with the time periods

CREATE TABLE local_authority."PM_TimePeriods_Transfer"
(
    id SERIAL,
    times_of_e character varying(254) COLLATE pg_catalog."default",
    "TimePeriodDescription" character varying(254) COLLATE pg_catalog."default",
    "AdditionalConditionDescription" character varying(254) COLLATE pg_catalog."default",
    "TimePeriodCode" integer,
    "AdditionalConditionCode" integer
)

TABLESPACE pg_default;

ALTER TABLE local_authority."PM_TimePeriods_Transfer"
    OWNER to postgres;

ALTER TABLE local_authority."PM_TimePeriods_Transfer"
    ADD PRIMARY KEY (id);

INSERT INTO local_authority."PM_TimePeriods_Transfer"(
	times_of_e)
SELECT DISTINCT times_of_e
FROM local_authority."PM_Lines_Transfer_Current";

--

ALTER TABLE local_authority."PM_TimePeriods_Transfer"
    ADD COLUMN revised_times_of_e character varying(254);

UPDATE local_authority."PM_TimePeriods_Transfer"
	SET revised_times_of_e=times_of_e;

UPDATE local_authority."PM_TimePeriods_Transfer"
	SET revised_times_of_e=
       concat(left(times_of_e, position('am' IN times_of_e)-1), '.00', right(times_of_e, -position('am' IN times_of_e)+1))
	WHERE position('am' IN times_of_e) < length (times_of_e);

UPDATE local_authority."PM_TimePeriods_Transfer" As p
SET revised_times_of_e=
        concat(left(revised_times_of_e, position('pm' IN revised_times_of_e)-1), '.00', right(revised_times_of_e, -position('pm' IN revised_times_of_e)+1))
	WHERE position('pm' IN revised_times_of_e) < length (revised_times_of_e)
	AND position('pm' IN revised_times_of_e) > 0;

UPDATE local_authority."PM_TimePeriods_Transfer" As p
SET revised_times_of_e=
        concat(left(revised_times_of_e, position(' and' IN revised_times_of_e)), right(revised_times_of_e, -(position(' and' IN revised_times_of_e)+4)))
	WHERE position(' and' IN revised_times_of_e) < length (revised_times_of_e)
	AND position(' and' IN revised_times_of_e) > 0;

UPDATE local_authority."PM_TimePeriods_Transfer" As p
SET revised_times_of_e = regexp_replace(revised_times_of_e, '.30.00', '.30', 'g');

UPDATE local_authority."PM_TimePeriods_Transfer" As p
SET revised_times_of_e = regexp_replace(revised_times_of_e, 'p.00m', 'pm', 'g');

UPDATE local_authority."PM_TimePeriods_Transfer" As p
SET revised_times_of_e = regexp_replace(revised_times_of_e, 'None.00', 'None', 'g');

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
 SET revised_times_of_e = regexp_replace(revised_times_of_e, '1am', '1.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
 SET revised_times_of_e = regexp_replace(revised_times_of_e, '2am', '2.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '3am', '3.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '4am', '4.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '5am', '5.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '6am', '6.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '7am', '7.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '8am', '8.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '9am', '9.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '10am', '10.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '11am', '11.00am', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '1pm', '1.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '2pm', '2.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '3pm', '3.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '4pm', '4.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '5pm', '5.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '6pm', '6.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '7pm', '7.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '8pm', '8.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '9pm', '9.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '10pm', '10.00pm', 'g')
;

UPDATE local_authority."PM_TimePeriods_Transfer" As p 
SET revised_times_of_e = regexp_replace(revised_times_of_e, '11pm', '11.00pm', 'g')
;


/***
SELECT ConCAT('INSERT INTO "toms_lookups"."TimePeriods" ("Description", "LabelText") VALUES (''', revised_times_of_e, ''', ''', revised_times_of_e,''');')
FROM local_authority."PM_TimePeriods_Transfer" As p
WHERE timeperiodcode is null
***/

-- try match

UPDATE local_authority."PM_TimePeriods_Transfer" As p
	SET "TimePeriodCode"=l."Code"
	FROM toms_lookups."TimePeriods" l
	WHERE p.revised_times_of_e = l."Description"
    AND p."TimePeriodCode" IS NULL;

-- now update

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "TimePeriodID" integer;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "TimePeriodID"=l."TimePeriodCode"
	FROM local_authority."PM_TimePeriods_Transfer" l
	WHERE p.times_of_e = l.times_of_e;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "TimePeriodID" = 0
	WHERE "times_of_e" =  '(None)';

-- add "GeometryID"
ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "GeometryID" character varying(12);

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "GeometryID"=item_ref;

-- add "GeomShapeID"
ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "GeomShapeID" integer;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "GeomShapeID"=1
	WHERE "RestrictionTypeID" < 200;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "GeomShapeID"=10
	WHERE "RestrictionTypeID" > 200;

-- Split out the lines and bays

DROP TABLE IF EXISTS local_authority."PM_Lines_Transfer_BayRestrictions_Current";

CREATE TABLE local_authority."PM_Lines_Transfer_BayRestrictions_Current"
AS
SELECT * FROM local_authority."PM_Lines_Transfer_Current_101"
WHERE "RestrictionTypeID" < 200;

ALTER TABLE local_authority."PM_Lines_Transfer_BayRestrictions_Current"
    OWNER to postgres;

ALTER TABLE local_authority."PM_Lines_Transfer_BayRestrictions_Current"
    ADD PRIMARY KEY (id);

DROP INDEX IF EXISTS local_authority."sidx_PM_Lines_Transfer_BayRestrictions_Current_geom";

CREATE INDEX "sidx_PM_Lines_Transfer_BayRestrictions_Current_geom"
    ON local_authority."PM_Lines_Transfer_BayRestrictions_Current" USING gist
    (geom)
    TABLESPACE pg_default;


DROP TABLE IF EXISTS local_authority."PM_Lines_Transfer_LineRestrictions_Current";

CREATE TABLE local_authority."PM_Lines_Transfer_LineRestrictions_Current"
AS
SELECT * FROM local_authority."PM_Lines_Transfer_Current_101"
WHERE "RestrictionTypeID" > 200;

ALTER TABLE local_authority."PM_Lines_Transfer_LineRestrictions_Current"
    OWNER to postgres;

ALTER TABLE local_authority."PM_Lines_Transfer_LineRestrictions_Current"
    ADD PRIMARY KEY (id);

DROP INDEX IF EXISTS local_authority."sidx_PM_Lines_Transfer_LineRestrictions_Current_geom";

CREATE INDEX "sidx_PM_Lines_Transfer_LineRestrictions_Current_geom"
    ON local_authority."PM_Lines_Transfer_LineRestrictions_Current" USING gist
    (geom)
    TABLESPACE pg_default;


/****

-- if considering only the new restrictions

DROP TABLE IF EXISTS local_authority."Bays_Transfer" CASCADE;

CREATE TABLE local_authority."Bays_Transfer"
AS
SELECT id, item_ref, "Order_type", "Street_nam", "Length", restrictio, times_of_e, "Ord_Title", "oCashless_", "oCar_Club_",
       "bOrganisat", "bTariff", "bPandDMach", "bEchelon", "bNoBays", "bLocation", "oCar_club1", "RestrictionTypeID", "TimePeriodID", "GeometryID", "GeomShapeID",
       (ST_Dump(geom)).geom AS geom
FROM local_authority."PM_Lines_Transfer_Current_101"
WHERE "RestrictionTypeID" < 200
AND item_ref NOT IN
--(SELECT DISTINCT l.item_ref
--FROM mhtc_operations."Supply_2022" s, mhtc_operations."RBKC_item_ref_links_2022" l
--WHERE s."GeometryID" = l."GeometryID");
(SELECT DISTINCT item_ref
FROM local_authority."2022_PM_Lines_Transfer_Current");

DROP TABLE IF EXISTS local_authority."Lines_Transfer" CASCADE;

CREATE TABLE local_authority."Lines_Transfer"
AS
SELECT id, item_ref, "Order_type", "Street_nam", "Length", restrictio, times_of_e, "Ord_Title", "oCashless_", "oCar_Club_",
       "bOrganisat", "bTariff", "bPandDMach", "bEchelon", "bNoBays", "bLocation", "oCar_club1", "RestrictionTypeID", "TimePeriodID", "GeometryID", "GeomShapeID",
       (ST_Dump(geom)).geom AS geom
FROM local_authority."PM_Lines_Transfer_Current_101"
WHERE "RestrictionTypeID" > 200
AND item_ref NOT IN
--(SELECT DISTINCT l.item_ref
--FROM mhtc_operations."Supply_2022" s, mhtc_operations."RBKC_item_ref_links_2022" l
--WHERE s."GeometryID" = l."GeometryID");
(SELECT DISTINCT item_ref
FROM local_authority."2022_PM_Lines_Transfer_Current");

ALTER TABLE local_authority."Bays_Transfer"
    ADD PRIMARY KEY (id);

ALTER TABLE local_authority."Lines_Transfer"
    ADD PRIMARY KEY (id);

-- Ensure that control times are populated

UPDATE
***/

/***

SELECT DISTINCT o.item_ref
    FROM local_authority."2022_PM_Lines_Transfer_Current" o
    WHERE o."RestrictionTypeID" < 200
    AND o.item_ref NOT IN (
    SELECT item_ref
    FROM mhtc_operations."RBKC_item_ref_links_2022")

-- Add "missing" "Bay" item_ref values to link table

INSERT INTO mhtc_operations."RBKC_item_ref_links_2022"(item_ref, "GeometryID")
SELECT item_ref, "GeometryID"
FROM (
SELECT DISTINCT ON (s."item_ref") s."item_ref",
    cl."GeometryID" ,
	-- cl."roadName1_Name" AS "RoadName",
    ST_ClosestPoint(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS geom, ST_Distance(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS length
      FROM mhtc_operations."Supply_2022" cl, (
        SELECT o.item_ref, o.geom, o."RestrictionTypeID"
        FROM local_authority."2022_PM_Lines_Transfer_Current" o
        WHERE o."RestrictionTypeID" < 200
        AND o.item_ref NOT IN (
        SELECT item_ref
        FROM mhtc_operations."RBKC_item_ref_links_2022") ) s
	    WHERE cl."RestrictionTypeID" = s."RestrictionTypeID"
	  --WHERE LENGTH(cl."roadName1_Name") > 0
      ORDER BY s."item_ref", length
      ) a

-- and then add "missing" "Line" item_ref values to link table

SELECT DISTINCT o.item_ref
    FROM local_authority."2022_PM_Lines_Transfer_Current" o
    WHERE o."RestrictionTypeID" > 200
    AND o.item_ref NOT IN (
    SELECT item_ref
    FROM mhtc_operations."RBKC_item_ref_links_2022")


INSERT INTO mhtc_operations."RBKC_item_ref_links_2022"(item_ref, "GeometryID")
SELECT item_ref, "GeometryID"
FROM (
SELECT DISTINCT ON (s."item_ref") s."item_ref",
    cl."GeometryID" ,
	-- cl."roadName1_Name" AS "RoadName",
    ST_ClosestPoint(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS geom, ST_Distance(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS length
      FROM mhtc_operations."Supply_2022" cl, (
        SELECT o.item_ref, o.geom, o."RestrictionTypeID"
        FROM local_authority."2022_PM_Lines_Transfer_Current" o
        WHERE o."RestrictionTypeID" > 200
        AND o.item_ref NOT IN (
        SELECT item_ref
        FROM mhtc_operations."RBKC_item_ref_links_2022") ) s
	    WHERE cl."RestrictionTypeID" = s."RestrictionTypeID"
	  --WHERE LENGTH(cl."roadName1_Name") > 0
      ORDER BY s."item_ref", length
      ) a

-- consider SYLs

INSERT INTO mhtc_operations."RBKC_item_ref_links_2022"(item_ref, "GeometryID")
SELECT item_ref, "GeometryID"
FROM (
SELECT DISTINCT ON (s."item_ref") s."item_ref",
    cl."GeometryID" ,
	-- cl."roadName1_Name" AS "RoadName",
    ST_ClosestPoint(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS geom, ST_Distance(cl.geom, ST_LineInterpolatePoint(s.geom, 0.5)) AS length
      FROM mhtc_operations."Supply_2022" cl, (
        SELECT o.item_ref, o.geom, o."RestrictionTypeID"
        FROM local_authority."2022_PM_Lines_Transfer_Current" o
        WHERE o."RestrictionTypeID" = 224
        AND o.item_ref NOT IN (
        SELECT item_ref
        FROM mhtc_operations."RBKC_item_ref_links_2022") ) s
	    WHERE cl."RestrictionTypeID" IN (201, 221, 224)
	  --WHERE LENGTH(cl."roadName1_Name") > 0
      ORDER BY s."item_ref", length
      ) a


    ***/
