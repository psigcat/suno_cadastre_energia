DROP TABLE IF EXISTS [SCHEMA_NAME].building_plus CASCADE;
CREATE TABLE [SCHEMA_NAME].building_plus AS
SELECT 
   b.id as id, b.geom as geom,
   b.conditionofconstruction, b.beginning, b."end",
   UPPER(b.reference) as refcat, b.currentuse,
   b.numberofbuildingunits, b.numberofdwellings, b.numberoffloorsaboveground,
   b.value, b.value_uom
FROM cadastre_input.[TABLE_BUILDING] as b;

ALTER TABLE [SCHEMA_NAME].building_plus ADD PRIMARY KEY (id);


-- edificis 14, agafem la planta més alta de cada parcela i la posem a la taula building_plus
ALTER TABLE [SCHEMA_NAME].building_plus ADD COLUMN IF NOT EXISTS plantes integer;

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
UPDATE [SCHEMA_NAME].building_plus AS b
SET plantes = 0
WHERE plantes IS NULL;

-- Classifiquem els tipus d'habitatge
ALTER TABLE [SCHEMA_NAME].building_plus ADD COLUMN IF NOT EXISTS tipus_hab text;

UPDATE [SCHEMA_NAME].building_plus AS b
SET tipus_hab =
  CASE
    WHEN b.numberofdwellings = 1 THEN 'ResUnifamilar' --unifamiliar
    WHEN b.numberofdwellings > 1 AND b.plantes <3 THEN 'ResPlurifamBaix'
    WHEN b.numberofdwellings > 1 AND b.plantes >2 THEN 'ResPlurifamAlt'
    ELSE 'Altres'
  END;

-- Afegim el codi municipi a les constuccions
ALTER TABLE [SCHEMA_NAME].building_plus ADD COLUMN IF NOT EXISTS codi_ine integer;
UPDATE [SCHEMA_NAME].building_plus AS b
SET codi_ine = 
  ( SELECT m."CODIMUNI"
    FROM diccionari."Municipis" AS m
    WHERE ST_Within(b.geom, m.geom)
  );

-- Incorporem la zona climàtica del municipi
ALTER TABLE [SCHEMA_NAME].building_plus ADD COLUMN IF NOT EXISTS zona_clima text;
UPDATE [SCHEMA_NAME].building_plus AS b
SET zona_clima = 
  ( SELECT z.zona_climatica::text
    FROM diccionari.municipis_zones_climatiques AS z
    WHERE b.codi_ine = z.codi_idescat 
  );

