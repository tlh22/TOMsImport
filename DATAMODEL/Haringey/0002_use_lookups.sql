/***
Deal with time periods -- best done manually ...
1. Copy descriptions to relevant fields
2. Add relevent time period codes
***/

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "TimePeriodDescription" = TRIM ("TimePeriodDescription"),
    "MaxStayDescription" = TRIM ("MaxStayDescription"),
    "NoReturnDescription" = TRIM ("NoReturnDescription"),
    "MatchDayTimePeriodDescription" = TRIM ("MatchDayTimePeriodDescription"),
    "NoWaitingTimePeriodDescription" = TRIM ("NoWaitingTimePeriodDescription"),
    "NoLoadingTimePeriodDescription" = TRIM ("NoLoadingTimePeriodDescription");

-- DROP TABLE IF EXISTS local_authority."tmp_TimePeriods_Lookup_2" CASCADE;

CREATE TABLE local_authority."tmp_TimePeriods_Lookup_2"
(
    id SERIAL,
    "tmp_TimePeriodDescription" character varying COLLATE pg_catalog."default",
    "TimePeriodID" integer,
    CONSTRAINT "tmp_TimePeriods_Lookup_2_pkey" PRIMARY KEY (id)
);

INSERT INTO local_authority."tmp_TimePeriods_Lookup_2" ("tmp_TimePeriodDescription")
SELECT DISTINCT ("TimePeriod")
FROM (
SELECT DISTINCT "TimePeriodDescription" AS "TimePeriod"
FROM local_authority."tmp_TimePeriods_Lookup"
UNION
SELECT DISTINCT "MatchDayTimePeriodDescription" AS "TimePeriod"
FROM local_authority."tmp_TimePeriods_Lookup"
UNION
SELECT DISTINCT "NoWaitingTimePeriodDescription" AS "TimePeriod"
FROM local_authority."tmp_TimePeriods_Lookup"
UNION
SELECT DISTINCT "NoLoadingTimePeriodDescription" AS "TimePeriod"
FROM local_authority."tmp_TimePeriods_Lookup"
) d;

/***
Now apply lookups values
***/

-- Restrictions
UPDATE local_authority."tmp_All_Data" As t
SET "RestrictionTypeID" = l."RestrictionTypeID"
FROM local_authority."tmp_RestrictionType_Lookup" l
WHERE t."RestrictionTypeDescription" = l."RestrictionTypeDescription";

-- Time Periods

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "TimePeriodID" = l."TimePeriodID"
FROM local_authority."tmp_TimePeriods_Lookup_2" l
WHERE t."TimePeriodDescription" = l."tmp_TimePeriodDescription";

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "MatchDayTimePeriodID" = l."TimePeriodID"
FROM local_authority."tmp_TimePeriods_Lookup_2" l
WHERE t."MatchDayTimePeriodDescription" = l."tmp_TimePeriodDescription";

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "NoWaitingTimeID" = l."TimePeriodID"
FROM local_authority."tmp_TimePeriods_Lookup_2" l
WHERE t."NoWaitingTimePeriodDescription" = l."tmp_TimePeriodDescription";

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "NoLoadingTimeID" = l."TimePeriodID"
FROM local_authority."tmp_TimePeriods_Lookup_2" l
WHERE t."NoLoadingTimePeriodDescription" = l."tmp_TimePeriodDescription";

-- Max Stay / No return

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "MaxStayID" = l."Code"
FROM toms_lookups."LengthOfTime" l
WHERE t."MaxStayDescription" = l."LabelText";

UPDATE local_authority."tmp_TimePeriods_Lookup" As t
SET "NoReturnID" = l."Code"
FROM toms_lookups."LengthOfTime" l
WHERE t."NoReturnDescription" = l."LabelText";

--

UPDATE local_authority."tmp_All_Data" As t
SET "TimePeriodID" = l."TimePeriodID",
    "MaxStayID" = l."MaxStayID",
    "NoReturnID" = l."NoReturnID",
    "MatchDayTimePeriodID" = l."MatchDayTimePeriodID",
    "NoWaitingTimeID" = l."NoWaitingTimeID",
    "NoLoadingTimeID" = l."NoLoadingTimeID"
FROM local_authority."tmp_TimePeriods_Lookup" l
WHERE t."TimePeriodDescription" = l."tmp_TimePeriodDescription";