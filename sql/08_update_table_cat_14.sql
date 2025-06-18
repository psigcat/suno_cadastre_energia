-- edificis 14, fem la diferència entre superficie_total_efectos_catastro_m2 i superfície terrassa i la guardem a sup_calef
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS sup_calef integer;
UPDATE [SCHEMA_NAME].cat_14 SET sup_calef = superficie_total_efectos_catastro_m2 - superficie_porches_y_terrazas_m2;

-- edificis 14, definim quins usos son climatitzables
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS clima text;
UPDATE [SCHEMA_NAME].cat_14 AS c SET clima =
  (SELECT u.clima
   FROM diccionari.usos_cadastre AS u
   WHERE c.codigo_destino_dgc = u.codi_dgc
   )
;

-- edificis 14, definim la superficie climatitzable
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS superficie_clima integer;
UPDATE [SCHEMA_NAME].cat_14 AS c
SET superficie_clima = 
   CASE
      WHEN c.clima = 'no' THEN 0
      WHEN c.clima = 'si' THEN c.sup_calef
   END
;

-- edificis 14, passem el codi_dgc a un text que ens permet agrupar per úsos (residencial, terciari, industrial, exterior ...)
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS grup text;
UPDATE [SCHEMA_NAME].cat_14 AS c SET grup =
  (SELECT u.grup
   FROM diccionari.usos_cadastre AS u
   WHERE c.codigo_destino_dgc = u.codi_dgc
  )
;

-- -- edificis 14, amb la tipologia ja defifinida, la traslladem a cada vivenda 
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS tipus text;
UPDATE [SCHEMA_NAME].cat_14 AS c
SET tipus = 
  CASE 
      WHEN c.grup = 'residencial' THEN ( 
           SELECT tipus_hab
           FROM [SCHEMA_NAME].building_plus AS b
           WHERE  c.parcela_catastral = b.refcat 
           LIMIT 1)
      WHEN c.grup = 'terciari'    THEN 'GT01_SecSchool'
  END
;

-- Actualitzo 'superficie_clima' segons valors 'tipus' per definir la superfície climatitzada del total de edifici.
UPDATE [SCHEMA_NAME].cat_14 AS c
SET superficie_clima = 
   CASE
      WHEN c.tipus = 'ResUnifamilar'   THEN c.superficie_clima / 1.625
      WHEN c.tipus = 'ResPlurifamBaix' THEN c.superficie_clima / 1.68
      WHEN c.tipus = 'ResPlurifamAlt'  THEN c.superficie_clima / 1.68
      WHEN c.tipus = 'GT01_SecSchool'  THEN c.superficie_clima / 1.68
      WHEN c.tipus = 'altres'          THEN c.superficie_clima
   END
;

-- edificis 13, canvio el format de l'any de construcció i el copio a la taula 14
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS anyo_construccion integer;
UPDATE [SCHEMA_NAME].cat_14 AS c14
SET anyo_construccion = 
  (SELECT AVG(c13.anyo_construccion)
   FROM [SCHEMA_NAME].cat_13 AS c13
   WHERE  c14.parcela_catastral = c13.parcela_catastral
  )
;

-- edificis14, creo una columna amb l'any de referència, el més gran entre el de construcció i el de reforma
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS any_referencia integer;
UPDATE [SCHEMA_NAME].cat_14 AS c SET any_referencia = GREATEST(c.anyo_construccion, c.anyo_reforma);

-- Calculem època de l'any de referència
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS epoca_any_referencia text;
UPDATE [SCHEMA_NAME].cat_14 AS e14
SET epoca_any_referencia =
   CASE 
      WHEN e14.any_referencia < 1941                           THEN '<40'     -- < 40
      WHEN e14.any_referencia > 1940 AND any_referencia < 1961 THEN '41-60'   -- 41 - 60
      WHEN e14.any_referencia > 1960 AND any_referencia < 1981 THEN '61-80'   -- 61 - 80
      WHEN e14.any_referencia > 1980 AND any_referencia < 2008 THEN 'NBECT79' -- 81 - 07
      WHEN e14.any_referencia > 2007 AND any_referencia < 2015 THEN 'CTE2006' -- 08 - 13
      WHEN e14.any_referencia > 2014 AND any_referencia < 2021 THEN 'CTE2013' -- 14 - 19
      WHEN e14.any_referencia > 2020                           THEN 'CTE2019' -- > 20
   END
;

-- Calculem època de l'any de referència
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS epoca_any_rehabilitacio text;
UPDATE [SCHEMA_NAME].cat_14 AS e14
SET epoca_any_rehabilitacio =
   CASE 
      WHEN e14.any_referencia < 1941                           THEN 'CTE2013' -- < 40
      WHEN e14.any_referencia > 1940 AND any_referencia < 1961 THEN 'CTE2013' -- 41 - 60
      WHEN e14.any_referencia > 1960 AND any_referencia < 1981 THEN 'CTE2013' -- 61 - 80
      WHEN e14.any_referencia > 1980 AND any_referencia < 2008 THEN 'CTE2013' -- 81 - 07
      WHEN e14.any_referencia > 2007 AND any_referencia < 2015 THEN 'CTE2013' -- 08 - 13
      WHEN e14.any_referencia > 2014 AND any_referencia < 2021 THEN 'CTE2013' -- 14 - 19
      WHEN e14.any_referencia > 2020                           THEN 'CTE2019' -- > 20
   END
;

-- incorporo la ocupació a cada "vivenda". Provisionalment deixo 1 a esperes de definir-ho.
ALTER TABLE [SCHEMA_NAME].cat_14 ADD COLUMN IF NOT EXISTS perfil text;
UPDATE [SCHEMA_NAME].cat_14 AS c
SET perfil = 
   CASE
      WHEN c.tipus = 'ResPlurifamBaix' THEN 'Residencial'
      WHEN c.tipus = 'ResUnifamilar'   THEN 'Residencial'
      WHEN c.tipus = 'ResPlurifamAlt'  THEN 'Residencial'
      WHEN c.tipus = 'GT01_SecSchool'  THEN 'Terciari'
      ELSE 'altres'
   END
;

