
DROP TABLE IF EXISTS [SCHEMA_NAME].cat_13 CASCADE;
CREATE TABLE [SCHEMA_NAME].cat_13 AS
SELECT 
   CASE
   WHEN substring(cat_input FROM   3 for  4) is null or substring(cat_input FROM   3 for  4) = '' THEN 0
   ELSE substring(cat_input FROM   3 for  4)::integer  
   END  as anyo_expediente_admin,
   substring(cat_input FROM   7 for 13)::text       as ref_expediente_admin                                ,
   substring(cat_input FROM  20 for  3)::text       as codigo_entidad_colaboradora                         ,
   substring(cat_input FROM  23 for  1)::text       as tipo_movimiento                                     ,
   substring(cat_input FROM  24 for  2)::text       as codigo_delegacion_meh                               ,
   substring(cat_input FROM  26 for  3)::text       as codigo_municipio_dgc                                ,
   substring(cat_input FROM  29 for  2)::text       as clase_unidad_constructiva                           ,
   substring(cat_input FROM  31 for 14)::text       as parcela_catastral                                   ,
   substring(cat_input FROM  45 for  4)::text       as codigo_unidad_constructiva                          ,
-- substring(cat_input FROM  49 for  2)::text       as espais_en_blanc                                     ,
   substring(cat_input FROM  51 for  2)::text       as codigo_provincia_ine                                ,
   substring(cat_input FROM  53 for 25)::text       as nombre_provincia                                    ,
   substring(cat_input FROM  78 for  3)::text       as codigo_municipio_dgc_2                              ,
   substring(cat_input FROM  81 for  3)::text       as codigo_municipio_ine                                ,
   substring(cat_input FROM  84 for 40)::text       as nombre_municipio                                    ,
   substring(cat_input FROM 124 for 30)::text       as nombre_entidad_menor                                ,
   substring(cat_input FROM 154 for  5)::text       as codigo_via_publica_dgc                              ,
   substring(cat_input FROM 159 for  5)::text       as tipo_via                                            ,
   substring(cat_input FROM 164 for 25)::text       as nombre_via                                          ,
   CASE
   WHEN substring(cat_input FROM 189 for  4) is null or substring(cat_input FROM 189 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 189 for  4)::integer  
   END  as primer_numero_policia,
   substring(cat_input FROM 193 for  1)::text       as primera_letra                                       ,
   CASE
   WHEN substring(cat_input FROM 194 for  4) is null or substring(cat_input FROM 194 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 194 for  4)::integer  
   END  as segundo_numero_policia,
   substring(cat_input FROM 198 for  1)::text       as segunda_letra                                       ,
   CASE
   WHEN substring(cat_input FROM 199 for  4) is null or substring(cat_input FROM 199 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 199 for  4)::integer  
   END  as kilometro_por_cien,
   substring(cat_input FROM 216 for 25)::text       as direccion_no_estructurada                           ,
-- substring(cat_input FROM 241 for 55)::text       as espais_en_blanc_codigo_paraje                       ,
   CASE
   WHEN substring(cat_input FROM 296 for  4) is null or substring(cat_input FROM 296 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 296 for  4)::integer  
   END  as anyo_construccion,
   substring(cat_input FROM 300 for  1)::text       as exactitud_anyo_construccion                         , -- 'E'   as +'   as -'   as C'
   CASE
   WHEN substring(cat_input FROM 301 for  7) is null or substring(cat_input FROM 301 for  7) = '' THEN 0
   ELSE substring(cat_input FROM 301 for  7)::integer  
   END  as superficie_suelo_ocupado,
   CASE
   WHEN substring(cat_input FROM 308 for  5) is null or substring(cat_input FROM 308 for  5) = '' THEN 0
   ELSE substring(cat_input FROM 308 for  5)::integer  
   END  as longitud_fachada_cm,
   substring(cat_input FROM 313 for  5)::text       as codigo_via_publica                                  ,
   substring(cat_input FROM 318 for  3)::text       as codigo_tramo_via                                    ,
   substring(cat_input FROM 321 for  5)::text       as zona_valor_ponencia_valores                         ,
   substring(cat_input FROM 326 for  1)::text       as numero_fachadas                                     , --  N for 2 o 3
   substring(cat_input FROM 327 for  1)::text       as indicador_corrector_longitud_fachada                , --  S o N
   substring(cat_input FROM 328 for  1)::text       as indicador_corrector_estado_conservacion             , --  S o N
   substring(cat_input FROM 329 for  1)::text       as indicador_corrector_depreciacion_funcional          , --  S o N
   CASE
   WHEN substring(cat_input FROM 330 for  3) is null or substring(cat_input FROM 330 for  3) = '' THEN 0
   ELSE substring(cat_input FROM 330 for  3)::integer  
   END  as valor_coef_corrector_cargas_singulares,
   substring(cat_input FROM 333 for  1)::text       as indicador_aplic_corrector_especiales_extrinseco     , --  S o N
   substring(cat_input FROM 334 for  1)::text       as indicador_aplic_corrector_afecta_uso_no_lucrativo   , --  S o N
   substring(cat_input FROM 335 for  4)::text       as tipo_expediente_gerencia                            ,
   CASE
   WHEN substring(cat_input FROM 339 for  8) is null or substring(cat_input FROM 339 for  8) = '' or substring(cat_input FROM 339 for  8) = '00000000' THEN null
   ELSE to_date(substring(cat_input FROM 339 for  8), 'YYYYMMDD')::date  
   END  as fecha_alteracion_catastral,
-- substring(cat_input FROM 339 for  8)::integer    as fecha_alteracion_catastral                          ,
-- substring(cat_input FROM 339 for  8)::text       as fecha_alteracion_catastral                          ,
   CASE
   WHEN substring(cat_input FROM 347 for  4) is null or substring(cat_input FROM 347 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 347 for  4)::integer  
   END  as ejercicio_expediente_gerencia,
-- substring(cat_input FROM 351 for  2)::text       as espais_en_blanc                                     ,
   substring(cat_input FROM 353 for  8)::text       as referencia_expediente_gerencia                      ,
   substring(cat_input FROM 361 for  3)::text       as codigo_entidad_registro_expediente                  ,
   CASE
   WHEN substring(cat_input FROM 364 for  4) is null or substring(cat_input FROM 364 for  4) = '' THEN 0
   ELSE substring(cat_input FROM 364 for  4)::integer  
   END  as ejercicio_expediente_origen,
   substring(cat_input FROM 368 for 13)::text       as referencia_expediente_origena                       ,
   substring(cat_input FROM 381 for  3)::text       as codigo_entidad_origen_expediente                    ,
   substring(cat_input FROM 384 for 15)::text       as desc_codigo_destino                                 ,
   CASE
   WHEN substring(cat_input FROM 399 for 11) is null or substring(cat_input FROM 399 for 11) = '' THEN 0
   ELSE substring(cat_input FROM 399 for 11)::integer  
   END  as valor_unitario_suelo,
   substring(cat_input FROM 410 for  4)::text       as codigo_unidad_constructiva_matriz      

FROM cadastre_alfa_input.a[COD_MUNI]_alfa
WHERE SUBSTRING(cat_input FROM 1 FOR 2) = '13'
;

-- Generem la clau primària
ALTER TABLE [SCHEMA_NAME].cat_13 ADD PRIMARY KEY (parcela_catastral, codigo_unidad_constructiva);



-- Fí




