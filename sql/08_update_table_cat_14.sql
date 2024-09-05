
-- edificis 14, fem la diferència entre superficie_total_efectos_catastro_m2 i superfície terrassa i la guardem a sup_calef
alter table [SCHEMA_NAME].cat_14 add column if not exists sup_calef integer;
update [SCHEMA_NAME].cat_14 set sup_calef = superficie_total_efectos_catastro_m2 - superficie_porches_y_terrazas_m2;

-- edificis 14, definim quins usos son climatitzables
alter table [SCHEMA_NAME].cat_14 add column if not exists clima text;
update [SCHEMA_NAME].cat_14 as c set clima =
  (select u.clima
   from diccionari.usos_cadastre as u
   where c.codigo_destino_dgc = u.codi_dgc
   )
;

-- edificis 14, definim la superficie climatitzable
alter table [SCHEMA_NAME].cat_14 add column if not exists superficie_clima integer;
update [SCHEMA_NAME].cat_14 as c
set superficie_clima = 
   CASE
      when c.clima = 'no' then 0
      when c.clima = 'si' then c.sup_calef
   end
;

-- edificis 14, passem el codi_dgc a un text que ens permet agrupar per úsos (residencial, terciari, industrial, exterior ...)
alter table [SCHEMA_NAME].cat_14 	add column if not exists grup text;
update [SCHEMA_NAME].cat_14 as c set grup =
  (SELECT u.grup
   from diccionari.usos_cadastre as u
   where c.codigo_destino_dgc = u.codi_dgc
  )
;

-- -- edificis 14, amb la tipologia ja defifinida, la traslladem a cada vivenda 
alter table [SCHEMA_NAME].cat_14
	add column if not exists tipus text;
update [SCHEMA_NAME].cat_14 as c
set tipus = 
  CASE 
      WHEN c.grup = 'residencial' THEN ( 
           select tipus_hab
           from [SCHEMA_NAME].building_plus as b
           where  c.parcela_catastral = b.refcat 
           LIMIT 1)
      WHEN c.grup = 'terciari'    THEN 'GT01_SecSchool'
  end
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
alter table [SCHEMA_NAME].cat_14	add column if not exists anyo_construccion integer;
update [SCHEMA_NAME].cat_14 as c14
set anyo_construccion = 
  (select avg(c13.anyo_construccion)
   from [SCHEMA_NAME].cat_13 as c13
   where  c14.parcela_catastral = c13.parcela_catastral
  )
;

-- edificis14, creo una columna amb l'any de referència, el més gran entre el de construcció i el de reforma
alter table [SCHEMA_NAME].cat_14	add column if not exists any_referencia integer;
update [SCHEMA_NAME].cat_14 as c set any_referencia = greatest(c.anyo_construccion, c.anyo_reforma);

-- Calculem època de l'any de referència
alter table [SCHEMA_NAME].cat_14 add column if not exists epoca_any_referencia text;
update [SCHEMA_NAME].cat_14 as e14
set epoca_any_referencia =
   case 
      when e14.any_referencia < 1941                           then '<40'     -- < 40
      when e14.any_referencia > 1940 and any_referencia < 1961 then '41-60'   -- 41 - 60
      when e14.any_referencia > 1960 and any_referencia < 1981 then '61-80'   -- 61 - 80
      when e14.any_referencia > 1980 and any_referencia < 2008 then 'NBECT79' -- 81 - 07
      when e14.any_referencia > 2007 and any_referencia < 2015 then 'CTE2006' -- 08 - 13
      when e14.any_referencia > 2014 and any_referencia < 2021 then 'CTE2013' -- 14 - 19
      when e14.any_referencia > 2020                           then 'CTE2019' -- > 20
   end
;

-- Calculem època de l'any de referència
alter table [SCHEMA_NAME].cat_14 add column if not exists epoca_any_rehabilitacio text;
update [SCHEMA_NAME].cat_14 as e14
set epoca_any_rehabilitacio =
   case 
      when e14.any_referencia < 1941                           then 'CTE2013' -- < 40
      when e14.any_referencia > 1940 and any_referencia < 1961 then 'CTE2013' -- 41 - 60
      when e14.any_referencia > 1960 and any_referencia < 1981 then 'CTE2013' -- 61 - 80
      when e14.any_referencia > 1980 and any_referencia < 2008 then 'CTE2013' -- 81 - 07
      when e14.any_referencia > 2007 and any_referencia < 2015 then 'CTE2013' -- 08 - 13
      when e14.any_referencia > 2014 and any_referencia < 2021 then 'CTE2013' -- 14 - 19
      when e14.any_referencia > 2020                           then 'CTE2019' -- > 20
   end
;

-- incorporo la ocupació a cada "vivenda". Provisionalment deixo 1 a esperes de definir-ho.
alter table [SCHEMA_NAME].cat_14 	add column if not exists perfil text;
update [SCHEMA_NAME].cat_14 as c
set perfil = 
   CASE
      when c.tipus = 'ResPlurifamBaix' then 'Residencial'
      when c.tipus = 'ResUnifamilar'   then 'Residencial'
      when c.tipus = 'ResPlurifamAlt'  then 'Residencial'
      when c.tipus = 'GT01_SecSchool'  then 'Terciari'
      else 'altres'
   end
;

