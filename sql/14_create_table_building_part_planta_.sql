
-- Primer agrupem les geometries de la mateixa refcat
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster AS
SELECT 
    ST_Union(c.geom) AS geom, c.refcat, max(c.part) as max_part,
    min(c.z_min) as z_min, max(c.z_max) as z_max, avg(c.z_mean)::numeric(5,1) as z_mean,    
    [ALTURA]::float as altura_m, st_area(st_union(c.geom))::numeric(10,2) as area_planta_[PLANTA]
FROM
  ( SELECT 
     ST_ClusterDBSCAN(b.geom, eps := 0.1, minpoints := 1) OVER () AS cluster_id, 
     b.id, b.geom, b.refcat, b.part, b.z_min, b.z_max, b.z_mean
   FROM [SCHEMA_NAME].building_part_plus_z as b
   WHERE b.numberoffloorsaboveground > [NUM_PLANTA] ) as c
GROUP BY c.refcat, c.cluster_id;

-- Segon separem les que no es toquen. pasem de multi part a single part
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump AS
SELECT 
	(ST_Dump(geom)).geom AS geom, c.refcat, max_part, z_min, z_max, z_mean, altura_m, area_planta_[PLANTA]
FROM [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster as c;

DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_1_cluster CASCADE;

-- Tercer afegim un autoincrement per a cada refcat
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA] CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] AS
SELECT 
	ROW_NUMBER() OVER (PARTITION BY refcat ORDER BY st_area(geom) desc) AS id_room,
	geom, c.refcat, max_part, z_min, z_max, z_mean, altura_m, area_planta_[PLANTA]
FROM [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump as c;

DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_planta_[PLANTA]_2_dump CASCADE;

-- Afegir camp 'id_2' que servirà com a Primary Key
-- refcat_planta[PLANTA]_room[ROOM] 
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] add column id_2 text;
UPDATE [SCHEMA_NAME].building_part_planta_[PLANTA] as b
SET id_2 = refcat::text || '_planta[PLANTA]_room' || LPAD(id_room::text, 2, '0');

ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ADD PRIMARY KEY (id_2);

-- Camp de geometria
ALTER TABLE [SCHEMA_NAME].building_part_planta_[PLANTA] ALTER COLUMN geom SET DATA TYPE geometry(POLYGON, 25831) ;

-- Afegir any de referencia
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column any_referencia integer;
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set any_referencia =
  (select max(c14.any_referencia)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.planta in ([C14_PLANTA])
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set any_referencia = 0 where any_referencia is null;

-- Afegir zona climàtica
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column zona_clima text;
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set zona_clima =
  (select max(c14.zona_clima)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.planta in ([C14_PLANTA])
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set zona_clima = 0 where zona_clima is null;

-- Afegir us principal codi
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column us_principal_codi text;
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set us_principal_codi =
  (select TRIM(c14.codigo_destino_dgc)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.planta in ([C14_PLANTA])
  order by c14.superficie_total_efectos_catastro_m2 desc
  limit 1
  )
;

-- Afegir us principal nom
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column if not exists us_principal_nom text;
update [SCHEMA_NAME].building_part_planta_[PLANTA] as c set us_principal_nom = 
  (select TRIM(u.nom_dgc)
   from diccionari.usos_cadastre as u
   where c.us_principal_codi = u.codi_dgc
   )
;

-- Afegir camps per determinar àrees
-- Residencial
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column area_planta_[PLANTA]_residencial numeric(10,2);
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set area_planta_[PLANTA]_residencial =
  (select sum(c14.superficie_total_efectos_catastro_m2)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.grup = 'residencial' and c14.planta in ([C14_PLANTA])
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set area_planta_[PLANTA]_residencial = 0 where area_planta_[PLANTA]_residencial is null;

-- Terciari
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column area_planta_[PLANTA]_terciari numeric(10,2);
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set area_planta_[PLANTA]_terciari =
  (select sum(c14.superficie_total_efectos_catastro_m2)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.grup = 'terciari' and c14.planta in ([C14_PLANTA]) 
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set area_planta_[PLANTA]_terciari = 0 where area_planta_[PLANTA]_terciari is null;

-- Industrial
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column area_planta_[PLANTA]_industrial numeric(10,2);
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set area_planta_[PLANTA]_industrial =
  (select sum(c14.superficie_total_efectos_catastro_m2)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.grup = 'industrial' and c14.planta in ([C14_PLANTA]) 
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set area_planta_[PLANTA]_industrial = 0 where area_planta_[PLANTA]_industrial is null;

-- Exterior
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column area_planta_[PLANTA]_exterior numeric(10,2);
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set area_planta_[PLANTA]_exterior =
  (select sum(c14.superficie_total_efectos_catastro_m2)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.grup = 'exterior' and c14.planta in ([C14_PLANTA]) 
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set area_planta_[PLANTA]_exterior = 0 where area_planta_[PLANTA]_exterior is null;

-- Altres
alter table [SCHEMA_NAME].building_part_planta_[PLANTA] add column area_planta_[PLANTA]_altres numeric(10,2);
update [SCHEMA_NAME].building_part_planta_[PLANTA] as b
set area_planta_[PLANTA]_altres =
  (select sum(c14.superficie_total_efectos_catastro_m2)
  from [SCHEMA_NAME].cat_14 as c14 
  where b.refcat = c14.parcela_catastral and c14.grup = 'altres' and c14.planta in ([C14_PLANTA]) 
  )
;
update [SCHEMA_NAME].building_part_planta_[PLANTA] set area_planta_[PLANTA]_altres = 0 where area_planta_[PLANTA]_altres is null;

