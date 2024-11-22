-- make sure all road names are sentence CASE


UPDATE mhtc_operations."Supply"
SET "RoadName" = initcap("RoadName");

UPDATE mhtc_operations."Supply"
SET "RoadName" = REPLACE ("RoadName", E'\'S', E'\'s')
WHERE "RoadName" LIKE E'%\'S%';