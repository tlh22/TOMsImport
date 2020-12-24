-- Table: local_authority.All Confirmed Orders_lines

-- DROP TABLE local_authority."All Confirmed Orders_lines";

CREATE TABLE local_authority."PM_Lines_Transfer_Current"
(
    id SERIAL,
    geom geometry(LineString,27700),
    pmid bigint,
    order_type character varying(50) COLLATE pg_catalog."default",
    street_nam character varying(100) COLLATE pg_catalog."default",
    side_of_ro character varying(60) COLLATE pg_catalog."default",
    schedule character varying(15) COLLATE pg_catalog."default",
    mr_schedul character varying(15) COLLATE pg_catalog."default",
    nsg character varying(10) COLLATE pg_catalog."default",
    zoneno bigint,
    no_of_spac bigint,
    echelon character varying(1) COLLATE pg_catalog."default",
    times_of_e character varying(254) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    OWNER to postgres;

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD PRIMARY KEY (id);

-- use a transfer table

INSERT INTO local_authority."PM_Lines_Transfer_Current"(
	pmid, order_type, street_nam, side_of_ro, schedule, mr_schedul, nsg, zoneno, no_of_spac, echelon, times_of_e, geom)
SELECT pmid, order_type, street_nam, side_of_ro, schedule, mr_schedul, nsg, zoneno, no_of_spac, echelon, times_of_e, (ST_Dump(geom)).geom AS geom
FROM local_authority."All Confirmed Orders_lines"
WHERE date_to IS NULL;

-- deal with the restriction types

CREATE TABLE local_authority."PM_RestrictionTypes_Transfer"
(
    id SERIAL,
    order_type character varying(50) COLLATE pg_catalog."default",
    BayLineTypeCode integer
)

TABLESPACE pg_default;

ALTER TABLE local_authority."PM_RestrictionTypes_Transfer"
    OWNER to postgres;

ALTER TABLE local_authority."PM_RestrictionTypes_Transfer"
    ADD PRIMARY KEY (id);

INSERT INTO local_authority."PM_RestrictionTypes_Transfer"(
	order_type)
SELECT DISTINCT order_type
FROM local_authority."PM_Lines_Transfer_Current";

UPDATE local_authority."PM_RestrictionTypes_Transfer" As p
	SET baylinetypecode=l."Code"
	FROM toms_lookups."BayLineTypes" l
	WHERE p.order_type = l."Description";

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "RestrictionTypeID" integer;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "RestrictionTypeID"=l.baylinetypecode
	FROM local_authority."PM_RestrictionTypes_Transfer" l
	WHERE p.order_type = l.order_type;

-- deal with the time periods

CREATE TABLE local_authority."PM_TimePeriods_Transfer"
(
    id SERIAL,
    times_of_e character varying(254) COLLATE pg_catalog."default",
    TimePeriodsCode integer
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

-- try match

UPDATE local_authority."PM_TimePeriods_Transfer" As p
	SET TimePeriodsCode=l."Code"
	FROM toms_lookups."TimePeriods" l
	WHERE p.revised_times_of_e = l."Description";

-- now update

ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "TimePeriodID" integer;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "TimePeriodID"=l.TimePeriodsCode
	FROM local_authority."PM_TimePeriods_Transfer" l
	WHERE p.times_of_e = l.times_of_e;

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "TimePeriodID" = 0
	WHERE "times_of_e" =  '(None)';

-- add "GeometryID"
ALTER TABLE local_authority."PM_Lines_Transfer_Current"
    ADD COLUMN "GeometryID" character varying(12);

UPDATE local_authority."PM_Lines_Transfer_Current" As p
	SET "GeometryID"=pmid;

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

-- DROP TABLE local_authority."PM_Transfer_LineRestrictions";

CREATE TABLE local_authority."PM_Lines_Transfer_BayRestrictions_Current"
AS
SELECT * FROM local_authority."PM_Lines_Transfer_Current"
WHERE "RestrictionTypeID" < 200;

ALTER TABLE local_authority."PM_Lines_Transfer_BayRestrictions_Current"
    OWNER to postgres;
-- Index: sidx_PM_Transfer_LineRestrictions_geom

ALTER TABLE local_authority."PM_Lines_Transfer_BayRestrictions_Current"
    ADD PRIMARY KEY (id);

-- DROP INDEX local_authority."sidx_PM_Transfer_LineRestrictions_geom";

CREATE INDEX "sidx_PM_Lines_Transfer_BayRestrictions_Current_geom"
    ON local_authority."PM_Lines_Transfer_BayRestrictions_Current" USING gist
    (geom)
    TABLESPACE pg_default;


-- DROP TABLE local_authority."PM_Transfer_LineRestrictions";

CREATE TABLE local_authority."PM_Lines_Transfer_LineRestrictions_Current"
AS
SELECT * FROM local_authority."PM_Lines_Transfer_Current"
WHERE "RestrictionTypeID" > 200;

ALTER TABLE local_authority."PM_Lines_Transfer_LineRestrictions_Current"
    OWNER to postgres;
-- Index: sidx_PM_Transfer_LineRestrictions_geom

ALTER TABLE local_authority."PM_Lines_Transfer_LineRestrictions_Current"
    ADD PRIMARY KEY (id);

-- DROP INDEX local_authority."sidx_PM_Transfer_LineRestrictions_geom";

CREATE INDEX "sidx_PM_Lines_Transfer_LineRestrictions_Current_geom"
    ON local_authority."PM_Lines_Transfer_LineRestrictions_Current" USING gist
    (geom)
    TABLESPACE pg_default;

