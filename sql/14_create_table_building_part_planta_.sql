-- Primer agrupem les geometries de la mateixa refcat
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster AS
SELECT 
    ST_Union(c.geom) AS geom, c.refcat, MAX(c.part) AS max_part,
    MIN(c.z_min) AS z_min, MAX(c.z_max) AS z_max, AVG(c.z_mean)::numeric(5,1) AS z_mean,    
    [ALTURA]::float AS altura_m, ST_Area(ST_Union(c.geom))::numeric(10,2) AS area_planta_[PLANTA]
FROM
  ( SELECT 
     ST_ClusterDBSCAN(b.geom, eps := 0.1, minpoints := 1) OVER () AS cluster_id, 
     b.id, b.geom, b.refcat, b.part, b.z_min, b.z_max, b.z_mean
   FROM [SCHEMA_NAME].building_part_plus_z AS b
   WHERE b.numberoffloorsaboveground > [NUM_PLANTA] ) AS c
GROUP BY c.refcat, c.cluster_id;

-- Segon separem les que no es toquen. pasem de multi part a single part
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump AS
SELECT 
	(ST_Dump(geom)).geom AS geom, c.refcat, max_part, z_min, z_max, z_mean, altura_m, area_planta_[PLANTA]
FROM [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster AS c;

DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster CASCADE;

-- Tercer afegim un autoincrement per a cada refcat
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA] CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] AS
SELECT 
	ROW_NUMBER() OVER (PARTITION BY refcat ORDER BY ST_Area(geom) DESC) AS id_room,
	geom, c.refcat, max_part, z_min, z_max, z_mean, altura_m, area_planta_[PLANTA]
FROM [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump AS c;

DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump CASCADE;

-- Afegir camp 'id_2' que servirà com a Primary Key
-- refcat_planta[PLANTA]_room[ROOM] 
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN id_2 text;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET id_2 = refcat::text || '_planta[PLANTA]_room' || LPAD(id_room::text, 2, '0');

ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD PRIMARY KEY (id_2);

-- Camp de geometria
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ALTER COLUMN geom SET DATA TYPE geometry(POLYGON, 25831) ;

-- Afegir any de referencia
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN any_referencia integer;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET any_referencia =
  (SELECT MAX(c14.any_referencia)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.planta IN ([C14_PLANTA])
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET any_referencia = 0 WHERE any_referencia IS NULL;

-- Afegir zona climàtica
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN zona_clima text;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET zona_clima =
  (SELECT MAX(c14.zona_clima)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.planta IN ([C14_PLANTA])
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET zona_clima = 0 WHERE zona_clima IS NULL;

-- Afegir us principal codi
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN us_principal_codi text;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET us_principal_codi =
  (SELECT TRIM(c14.codigo_destino_dgc)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.planta IN ([C14_PLANTA])
  ORDER BY c14.superficie_total_efectos_catastro_m2 DESC
  LIMIT 1
  )
;

-- Afegir us principal nom
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN IF NOT EXISTS us_principal_nom text;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS c SET us_principal_nom = 
  (SELECT TRIM(u.nom_dgc)
   FROM diccionari.usos_cadastre AS u
   WHERE c.us_principal_codi = u.codi_dgc
   )
;

-- Afegir camps per determinar àrees
-- Residencial
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN area_planta_[PLANTA]_residencial numeric(10,2);
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET area_planta_[PLANTA]_residencial =
  (SELECT SUM(c14.superficie_total_efectos_catastro_m2)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.grup = 'residencial' AND c14.planta IN ([C14_PLANTA])
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET area_planta_[PLANTA]_residencial = 0 WHERE area_planta_[PLANTA]_residencial IS NULL;

-- Terciari
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN area_planta_[PLANTA]_terciari numeric(10,2);
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET area_planta_[PLANTA]_terciari =
  (SELECT SUM(c14.superficie_total_efectos_catastro_m2)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.grup = 'terciari' AND c14.planta IN ([C14_PLANTA]) 
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET area_planta_[PLANTA]_terciari = 0 WHERE area_planta_[PLANTA]_terciari IS NULL;

-- Industrial
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN area_planta_[PLANTA]_industrial numeric(10,2);
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET area_planta_[PLANTA]_industrial =
  (SELECT SUM(c14.superficie_total_efectos_catastro_m2)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.grup = 'industrial' AND c14.planta IN ([C14_PLANTA]) 
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET area_planta_[PLANTA]_industrial = 0 WHERE area_planta_[PLANTA]_industrial IS NULL;

-- Exterior
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN area_planta_[PLANTA]_exterior numeric(10,2);
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET area_planta_[PLANTA]_exterior =
  (SELECT SUM(c14.superficie_total_efectos_catastro_m2)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.grup = 'exterior' AND c14.planta IN ([C14_PLANTA]) 
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET area_planta_[PLANTA]_exterior = 0 WHERE area_planta_[PLANTA]_exterior IS NULL;

-- Altres
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD COLUMN area_planta_[PLANTA]_altres numeric(10,2);
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] AS b
SET area_planta_[PLANTA]_altres =
  (SELECT SUM(c14.superficie_total_efectos_catastro_m2)
  FROM [SCHEMA_NAME].cat_14 AS c14 
  WHERE b.refcat = c14.parcela_catastral AND c14.grup = 'altres' AND c14.planta IN ([C14_PLANTA]) 
  )
;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] SET area_planta_[PLANTA]_altres = 0 WHERE area_planta_[PLANTA]_altres IS NULL;

