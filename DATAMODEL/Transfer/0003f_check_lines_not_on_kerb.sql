-- Check for lines that don't touch the kerb

SELECT r."GeometryID", r."RestrictionTypeID"
FROM toms."Lines" r, topography."road_casement" c
WHERE  ST_Disjoint(c.geom, ST_Buffer(r.geom, 0.1))