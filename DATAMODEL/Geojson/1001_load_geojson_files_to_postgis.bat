REM  1001_load_geojson_files_to_postgis WSP2503_SouthwarkAreas_Office "import_geojson" "Z:\WSP25-03 Southwark Areas\Office\Mapping\Geojson"

SET SERVICE_NAME=%1
SET SCHEMA=%2
SET SOURCE_FOLDER=%3
echo input params %SERVICE_NAME% %SCHEMA% %SOURCE_FOLDER%
@echo off
cd /d %SOURCE_FOLDER%

for %%f in (*.geojson) do (
    call :Sub %%f 
)

:Sub
set file="%*"
set table=%file:~0,-9%"
echo input file %SOURCE_FOLDER%/%file%
echo creating table %table%
@echo on
"C:\Program Files\QGIS 3.22.16\bin\ogr2ogr" -f "PostgreSQL" PG:"service=%SERVICE_NAME%" %SOURCE_FOLDER%/%file% -s_srs "EPSG:27700" -spat_srs "EPSG:27700" -overwrite -unsetFid -nln %SCHEMA%.%table% -skipfailures
@echo off
