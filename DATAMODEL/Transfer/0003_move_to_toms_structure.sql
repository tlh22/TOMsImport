-- take the tables with the processed records and move them to TOMs structure
INSERT INTO "toms_lookups"."TimePeriodsInUse" ("Code")
SELECT u."TimePeriodID"
FROM (
SELECT DISTINCT "TimePeriodID"
FROM local_authority."PM_BayRestrictions_processed"
WHERE "TimePeriodID" IS NOT NULL
UNION
SELECT DISTINCT "TimePeriodID"
FROM local_authority."PM_LineRestrictions_processed"
WHERE "TimePeriodID" IS NOT NULL ) u
WHERE u."TimePeriodID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."TimePeriodsInUse"
);

INSERT INTO "toms_lookups"."BayTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT l."RestrictionTypeID", 'LineString'
FROM local_authority."PM_BayRestrictions_processed" l
WHERE l."RestrictionTypeID" IS NOT NULL
AND l."RestrictionTypeID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."BayTypesInUse"
);

INSERT INTO "toms_lookups"."LineTypesInUse" ("Code", "GeomShapeGroupType")
SELECT DISTINCT l."RestrictionTypeID", 'LineString'
FROM local_authority."PM_LineRestrictions_processed" l
WHERE l."RestrictionTypeID" IS NOT NULL
AND l."RestrictionTypeID" NOT IN (
    SELECT "Code" FROM "toms_lookups"."LineTypesInUse"
);

--ALTER TABLE toms."Bays" DISABLE TRIGGER update_capacity_bays;

ALTER TABLE toms."Bays"
    ADD COLUMN "pmid" integer;

INSERT INTO toms."Bays"(
	geom, "Notes", "RoadName", "USRN", "CPZ", "NrBays", "RestrictionID", "GeometryID", "RestrictionTypeID", "TimePeriodID",  "GeomShapeID", "pmid")
SELECT (ST_Dump(geom)).geom AS geom, CONCAT(pmid, ' ', order_type, ' ',  street_nam, ' ', side_of_ro, ' ', schedule, ' ', mr_schedul, ' ', echelon, ' ', times_of_e) ,
    street_nam, nsg, zoneno, no_of_spac, uuid_generate_v4(), "GeometryID", "RestrictionTypeID", "TimePeriodID",  "GeomShapeID", "pmid"
	FROM local_authority."PM_BayRestrictions_processed";

--ALTER TABLE toms."Bays" ENABLE TRIGGER update_capacity_bays;

--ALTER TABLE toms."Lines" DISABLE TRIGGER update_capacity_lines;

ALTER TABLE toms."Lines"
    ADD COLUMN "pmid" integer;

INSERT INTO toms."Lines"(
	geom, "Notes", "RoadName", "USRN", "CPZ", "RestrictionID", "GeometryID", "RestrictionTypeID", "NoWaitingTimeID",  "GeomShapeID", "pmid")
SELECT (ST_Dump(geom)).geom AS geom, CONCAT(pmid, ' ', order_type, ' ',  street_nam, ' ', side_of_ro, ' ', schedule, ' ', mr_schedul, ' ', echelon, ' ', times_of_e) ,
    street_nam, nsg, zoneno, uuid_generate_v4(), "GeometryID", "RestrictionTypeID", "TimePeriodID",  "GeomShapeID", "pmid"
	FROM local_authority."PM_LineRestrictions_processed";

--ALTER TABLE toms."Lines" ENABLE TRIGGER update_capacity_lines;

-- Need to add Open date ...

