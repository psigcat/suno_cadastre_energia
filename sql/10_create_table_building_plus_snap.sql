

-- Fema la taula building_plus_snap
DROP TABLE IF EXISTS [SCHEMA_NAME].building_plus_snap CASCADE;
CREATE TABLE [SCHEMA_NAME].building_plus_snap AS
SELECT 
  b.id,
  st_snap (b.geom, (select st_union(c.geom) from [SCHEMA_NAME].building_plus as c
 where c.id <> b.id and st_intersects(c.geom,b.geom) ), 0.1) as geom,
  b.conditionofconstruction, b.beginning, b."end", b.refcat, b.currentuse,
  b.numberofbuildingunits, b.numberofdwellings, b.numberoffloorsaboveground,
  b.value, b.value_uom, b.plantes, b.tipus_hab, b.codi_ine, b.zona_clima   
FROM [SCHEMA_NAME].building_plus as b;

-- definimos la Primary Key, 
alter table [SCHEMA_NAME].building_plus_snap ADD PRIMARY KEY (id);

-- 
-- update [SCHEMA_NAME].building_plus_snap set geom = ST_Simplify(geom, 0.1);

-- Fí


-- Crear una capa per a cada planta
-- Agrupar per contacte i refcat
-- Afegir usos per plantes i percentatge 
-- Alçada 4m PB 3,2 la resta
-- Exportar a geojason cada planta per separat amb les dades