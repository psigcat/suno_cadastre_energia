-- Actualitzar camp amb el número d'habitatges
UPDATE [SCHEMA_NAME].building_part_planta_00 AS bpp 
SET numberofdwellings = 
  ( SELECT bp.numberofdwellings 
    FROM [SCHEMA_NAME].building_plus AS bp
    WHERE bp.refcat = bpp.refcat
  );

