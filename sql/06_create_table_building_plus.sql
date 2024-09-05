
DROP TABLE IF EXISTS [SCHEMA_NAME].building_plus CASCADE;
CREATE TABLE [SCHEMA_NAME].building_plus AS
SELECT 
   b.ogc_fid as id, b.geom as geom,
   b.conditionofconstruction, b.beginning, b."end",
   b.reference as refcat, b.currentuse,
   b.numberofbuildingunits, b.numberofdwellings, b.numberoffloorsaboveground,
   b.value, b.value_uom
FROM cadastre_input.[TABLE_BUILDING] as b;

-- definimos la Primary Key, 
alter table [SCHEMA_NAME].building_plus ADD PRIMARY KEY (id);


-- edificis 14, agafem la planta més alta de cada parcela i la posem a la taula building_plus
alter table [SCHEMA_NAME].building_plus add column if not exists plantes integer;

UPDATE [SCHEMA_NAME].building_plus AS b
SET plantes = (
   SELECT COALESCE(MAX(
     CASE 
       WHEN TRIM(c.planta) ~ '^[0-9]+$' THEN TRIM(c.planta)::integer
       ELSE 0
     END), 0)
   FROM [SCHEMA_NAME].cat_14 AS c
   WHERE b.refcat = c.parcela_catastral
);


-- Posem a cero els nuls
update [SCHEMA_NAME].building_plus as b
set plantes = 0
where plantes is null;

-- Classifiuem els tipus d'habitatge
alter table [SCHEMA_NAME].building_plus add column if not exists tipus_hab text;

update [SCHEMA_NAME].building_plus as b
set tipus_hab =
  CASE
    when b.numberofdwellings = 1 then 'ResUnifamilar' --unifamiliar
    when b.numberofdwellings > 1 and b.plantes <3 then 'ResPlurifamBaix'
    when b.numberofdwellings > 1 and b.plantes >2 then 'ResPlurifamAlt'
    else 'Altres'
  end
;

-- Afegim el codi municipi a les constuccions
alter table [SCHEMA_NAME].building_plus add column if not exists codi_ine integer;
update [SCHEMA_NAME].building_plus as b
 set codi_ine = 
 ( SELECT m."CODIMUNI"
   from diccionari."Municipis" as m
   where ST_Within(b.geom, m.geom)
 )
;

-- Incorporem la zona climàtica del municipi
alter table [SCHEMA_NAME].building_plus add column if not exists zona_clima text;
update [SCHEMA_NAME].building_plus as b
 set zona_clima = 
 ( SELECT z.zona_climatica::text
   from diccionari.municipis_zones_climatiques as z
   where b.codi_ine = z.codi_idescat 
 )
;

