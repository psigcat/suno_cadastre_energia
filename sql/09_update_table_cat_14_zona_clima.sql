

-- incorporo la zona climàtica a la vivenda, triga 27 segons
ALTER TABLE [SCHEMA_NAME].cat_14 add column IF NOT EXISTS zona_clima text;
UPDATE [SCHEMA_NAME].cat_14 AS c
SET zona_clima = b.zona_clima
FROM [SCHEMA_NAME].building_plus AS b
WHERE c.parcela_catastral = b.refcat;

-- a edificis14 tenim tipus, codi_any i zona_clima, creem una columna amb els 3 elements concatenats
ALTER TABLE [SCHEMA_NAME].cat_14	add column IF NOT EXISTS id_clima text ;
UPDATE [SCHEMA_NAME].cat_14 AS e14
SET id_clima = tipus || '_'  || zona_clima || '_' || perfil || '_' || epoca_any_referencia;	

-- a edificis14 tenim tipus, codi_any i zona_clima, creem una columna amb els 3 elements concatenats
ALTER TABLE [SCHEMA_NAME].cat_14	add column IF NOT EXISTS id_clima_rehab text ;
UPDATE [SCHEMA_NAME].cat_14 AS e14
SET id_clima_rehab = tipus || '_'  || zona_clima || '_' || perfil || '_' || epoca_any_rehabilitacio;	

