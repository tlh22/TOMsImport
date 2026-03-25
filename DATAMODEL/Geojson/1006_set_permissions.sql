/***

Allow view access to import_geojson schema

***/

REVOKE ALL ON ALL TABLES IN SCHEMA import_geojson FROM toms_public, toms_operator, toms_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA import_geojson TO toms_public, toms_operator, toms_admin;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA import_geojson TO toms_public, toms_operator, toms_admin;
GRANT USAGE ON SCHEMA import_geojson TO toms_public, toms_operator, toms_admin;