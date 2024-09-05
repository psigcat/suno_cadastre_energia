
-- Crear taula cat_14
DROP TABLE IF EXISTS [SCHEMA_NAME].cat_14 CASCADE;
CREATE TABLE [SCHEMA_NAME].cat_14 AS
SELECT 
   CASE
   WHEN substring(cat_input FROM   3 for  4) is null or substring(cat_input FROM   3 for  4) = '' THEN 0
   ELSE substring(cat_input FROM   3 for  4)::integer  
   END  as anyo_expediente_admin,
   substring(cat_input FROM   7 for 13)::text     as ref_expediente_admin   ,
   substring(cat_input FROM  20 for  3)::text     as codigo_entidad_colaboradora   ,
   substring(cat_input FROM  23 for  1)::text     as tipo_movimiento   , --A Alta, B Baja, M Modificación, F Situación Final
   substring(cat_input FROM  24 for  2)::text     as codigo_delegacion_meh   ,
   substring(cat_input FROM  26 for  3)::text     as codigo_municipio_dgc   ,
   substring(cat_input FROM  31 for 14)::text     as parcela_catastral   ,
   CASE
   WHEN substring(cat_input FROM  45 for  4) is null or substring(cat_input FROM  45 for  4) = '' THEN 0
   ELSE substring(cat_input FROM  45 for  4)::integer  
   END  as numero_orden_elemento_construccion,
-- substring(cat_input FROM  49 for  2)::text     as espais_en_blanc   ,
   substring(cat_input FROM  51 for  4)::text     as numero_orden_bien_inmueble   ,
   substring(cat_input FROM  55 for  4)::text     as codigo_unidad_constructiva_asociada   ,
   substring(cat_input FROM  59 for  4)::text     as bloque   ,
   substring(cat_input FROM  63 for  2)::text     as escalera   ,
   substring(cat_input FROM  65 for  3)::text     as planta   ,
   substring(cat_input FROM  68 for  3)::text     as puerta   ,
   substring(cat_input FROM  71 for  3)::text     as codigo_destino_dgc   ,
   substring(cat_input FROM  74 for  1)::text     as tipo_reforma_o_rehabilitacion   , -- 'R', 'O', 'E', 'I', ''
   CASE
   WHEN substring(cat_input FROM  75 for  4) is null or substring(cat_input FROM  75 for  4) = '' THEN 0
   ELSE substring(cat_input FROM  75 for  4)::integer  
   END  as anyo_reforma,
   CASE
   WHEN substring(cat_input FROM  79 for  4) is null or substring(cat_input FROM  79 for  4) = '' THEN 0
   ELSE substring(cat_input FROM  79 for  4)::integer  
   END  as anyo_antiguedad_efectiva_catastro,
   substring(cat_input FROM  83 for  1)::text     as indicador_local_interior   , -- 'S', 'N'
   CASE
   WHEN substring(cat_input FROM  84 for  7) is null or substring(cat_input FROM  84 for  7) = '' THEN 0
   ELSE substring(cat_input FROM  84 for  7)::integer  
   END  as superficie_total_efectos_catastro_m2,
   CASE
   WHEN substring(cat_input FROM  91 for  7) is null or substring(cat_input FROM  91 for  7) = '' THEN 0
   ELSE substring(cat_input FROM  91 for  7)::integer  
   END  as superficie_porches_y_terrazas_m2,
   CASE
   WHEN substring(cat_input FROM  98 for  7) is null or substring(cat_input FROM  98 for  7) = '' THEN 0
   ELSE substring(cat_input FROM  98 for  7)::integer  
   END  as superficie_imputable_en_otras_plantas_m2,
   substring(cat_input FROM 105 for  5)::text     as tipologia_constructiva   ,
   substring(cat_input FROM 110 for  1)::text     as codigo_uso_predominante   ,	
   substring(cat_input FROM 111 for  1)::text     as codigo_categoria_predominante   ,	
   substring(cat_input FROM 112 for  3)::text     as modalidad_reparto_elementos_comunes   ,
   substring(cat_input FROM 115 for  1)::text     as codigo_tipo_valor_aplicar   ,	-- 0 1 2 3 4 5 6 7 8 9 T teorica, N no consta, E equipamientos , V zona verde	
   substring(cat_input FROM 116 for  3)::text     as valor_coef_corrector_economica   ,
   substring(cat_input FROM 119 for  1)::text     as indicador_corrector_vivienda_interior   ,	-- S o N
   substring(cat_input FROM 120 for  4)::text     as tipo_expediente_gerencia   ,
   CASE
   WHEN substring(cat_input FROM 124 for  8) is null or substring(cat_input FROM 124 for  8) = '' or substring(cat_input FROM 124 for  8) = '00000000' THEN null
   ELSE to_date(substring(cat_input FROM 124 for  8), 'YYYYMMDD')::date  
   END  as fecha_alteracion_catastral,
   CASE
   WHEN substring(cat_input FROM 132 for  4) is null or substring(cat_input FROM 132 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 132 for  4)::integer  
   END  as ejercicio_expediente_gerencia,
-- substring(cat_input FROM 136 for  2)::text     as espais_en_blanc   ,
   substring(cat_input FROM 138 for  8)::text     as referencia_expediente_gerencia   ,	
   substring(cat_input FROM 146 for  3)::text     as codigo_entidad_registro_expediente   ,
   CASE
   WHEN substring(cat_input FROM 149 for  4) is null or substring(cat_input FROM 149 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 149 for  4)::integer  
   END  as ejercicio_expediente_origen,
   substring(cat_input FROM 153 for 13)::text     as referencia_expediente_origena   ,
   substring(cat_input FROM 166 for  3)::text     as codigo_entidad_origen_expediente   ,
   substring(cat_input FROM 169 for  7)::text     as valor_repercusion_suelo   ,
   CASE
   WHEN substring(cat_input FROM 176 for 11) is null or substring(cat_input FROM 176 for 114) = '' THEN 0
   ELSE substring(cat_input FROM 176 for 11)::integer  
   END  as valor_modulo_construccion_6d_o_2d_bice,
   substring(cat_input FROM 187 for 10)::text     as indicador_coeficientes_aplicados   ,
   substring(cat_input FROM 197 for  7)::text     as valor_coef_valor_suelo   ,
   substring(cat_input FROM 204 for  7)::text     as valor_coef_valor_construccion   ,
   substring(cat_input FROM 211 for  7)::text     as valor_coef_valor_suelo_constru   ,
-- substring(cat_input FROM 218 for 14)::text      as espais_en_blanc   ,
   substring(cat_input FROM 232 for 15)::text     as desc_codigo_destino   ,
   substring(cat_input FROM 247 for  4)::text     as g_b_aplic_constru_concreta

FROM cadastre_alfa_input.a[COD_MUNI]_alfa
WHERE SUBSTRING(cat_input FROM 1 FOR 2) = '14';

-- Generem la clau primària
ALTER TABLE [SCHEMA_NAME].cat_14 ADD PRIMARY KEY (parcela_catastral, numero_orden_elemento_construccion);


UPDATE [SCHEMA_NAME].cat_14 SET codigo_destino_dgc = TRIM(codigo_destino_dgc);

