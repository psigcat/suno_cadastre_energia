

-- Insertar dades de la planta indicada
INSERT INTO [SCHEMA_NAME].building_part_planta_juntes
SELECT 
    b.id_2, b.geom, b.refcat, id_room, b.max_part,
    '[PLANTA]'::integer AS num_planta,
    b.z_min, b.z_max, b.z_mean, b.altura_m,
    b.any_referencia, b.zona_clima,
    b.us_principal_codi, b.us_principal_nom,
    b.area_planta_[PLANTA] AS area_planta,
    b.area_planta_[PLANTA]_residencial  AS area_planta_residencial,
    b.area_planta_[PLANTA]_terciari     AS area_planta_terciari,
    b.area_planta_[PLANTA]_industrial   AS area_planta_industrial,
    b.area_planta_[PLANTA]_exterior     AS area_planta_exterior,
    b.area_planta_[PLANTA]_altres       AS area_planta_altres,
    0::integer                          AS numberofdwellings
FROM [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
ORDER BY refcat, num_planta, id_room;

