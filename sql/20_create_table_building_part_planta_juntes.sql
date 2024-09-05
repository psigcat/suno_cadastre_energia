

-- Crear taula 'building_part_planta_juntes'
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_juntes CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_juntes AS
SELECT 
   b.id_2, b.geom, b.refcat, id_room, b.max_part,
   0::integer as num_planta,
   b.z_min, b.z_max, b.z_mean, b.altura_m,
   b.any_referencia, b.zona_clima,
   b.us_principal_codi, b.us_principal_nom,
   b.area_planta_00 as area_planta,
   b.area_planta_00_residencial as area_planta_residencial,
   b.area_planta_00_terciari    as area_planta_terciari,
   b.area_planta_00_industrial  as area_planta_industrial,
   b.area_planta_00_exterior    as area_planta_exterior,
   b.area_planta_00_altres      as area_planta_altres
FROM [SCHEMA_NAME].building_part_planta_00 as b
ORDER BY refcat, num_planta, id_room;

ALTER TABLE [SCHEMA_NAME].building_part_planta_juntes ADD PRIMARY KEY (id_2);
ALTER TABLE [SCHEMA_NAME].building_part_planta_juntes ALTER COLUMN geom SET DATA TYPE geometry(POLYGON, 25831);