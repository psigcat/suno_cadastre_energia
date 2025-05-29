


-- Fitxer per executar l'actualització del plugin on volem obtenir la suma total de superfícies de tipus resicendials i després fer una repartició per plantes.
-- La definició i execució d'aquest fitxer en el plugin es troba en en Suno_task.py 


-- He sustituido "{0}"  per [SCHEMA_NAME]

-- Primera part: Suma de superfícies residencials per edifici


        DROP TABLE IF EXISTS [SCHEMA_NAME].temp_superficie_residencial;
        
        CREATE TABLE [SCHEMA_NAME].temp_superficie_residencial AS
        SELECT 
            b.id, 
            b.geom,
            b.refcat,
            SUM(c14.superficie_total_efectos_catastro_m2) AS sup_total_residencial,
            
            ARRAY_AGG(DISTINCT c14.planta) AS plantas_residenciales,
            COUNT(DISTINCT c14.planta) AS num_plantas_residenciales,
            
            SUM(CASE 
                WHEN c14.planta IN ('AL ', 'SM ', 'OP ') THEN c14.superficie_total_efectos_catastro_m2 * 0.5
                ELSE c14.superficie_total_efectos_catastro_m2 
            END) AS sup_total_ajustada
        
        FROM [SCHEMA_NAME].cat_14 AS c14
        JOIN [SCHEMA_NAME].building_plus AS b 
            ON b.refcat = c14.parcela_catastral
        WHERE c14.grup = 'residencial'
          AND c14.superficie_total_efectos_catastro_m2 > 0
        GROUP BY b.id, b.geom, b.refcat;






	 /*
	  CREATE TABLE [SCHEMA_NAME].temp_superficie_residencial AS
        SELECT 
            b.id, b.geom,
			b.refcat,
            SUM(c14.superficie_total_efectos_catastro_m2) AS sup_total_residencial,
            MAX(bp.numberoffloorsaboveground) AS num_plantas,
            SUM(CASE 
                WHEN c14.planta IN ('PB', 'AP', 'AT') THEN c14.superficie_total_efectos_catastro_m2 * 0.5
                ELSE c14.superficie_total_efectos_catastro_m2 
            END) AS sup_total_ajustada
        FROM [SCHEMA_NAME].cat_14 AS c14
        JOIN [SCHEMA_NAME].building_plus AS b 
            ON b.refcat = c14.parcela_catastral
        JOIN [SCHEMA_NAME].building_part_plus AS bp 
            ON bp.refcat = b.refcat
        WHERE c14.grup = 'residencial'
          AND c14.superficie_total_efectos_catastro_m2 > 0
          --AND c14.planta NOT IN ('AL', 'PK', 'SM', 'PT', 'PL', 'RS', 'PTA')
        GROUP BY b.id, b.geom, b.refcat;
	  */

 
 
 -- Segona part: Distribució de la superfície total en totes les plantes ?
                
    
        ALTER TABLE [SCHEMA_NAME].temp_superficie_residencial ADD COLUMN IF NOT EXISTS sup_residencial_distribuida NUMERIC(10,2);
        UPDATE [SCHEMA_NAME].temp_superficie_residencial AS b
        SET sup_residencial_distribuida = t.sup_total_ajustada / NULLIF(t.num_plantas_residenciales, 0)
        FROM [SCHEMA_NAME].temp_superficie_residencial AS t
        WHERE b.refcat = t.refcat;
      


/*

Funcions antigues que es trobaven entre def exec_zonal_stats(self) i def get_ogr2ogr(self)



    def calculate_residential_surface(self):
        """ Calcular la superficie total residencial por edificio """
        
        log_info("Calculando superficie total residencial...")
        
        sql_residential_surface = """
        -- Crear una tabla temporal con la suma de superficies residenciales por edificio
        DROP TABLE IF EXISTS "{0}".temp_superficie_residencial;  -- Aquí eliminarías la tabla si existiera
        CREATE TABLE "{0}".temp_superficie_residencial AS
        SELECT 
            b.refcat,
            SUM(c14.superficie_total_efectos_catastro_m2) AS sup_total_residencial,
            bp.numberoffloorsaboveground AS num_plantas,
            SUM(CASE 
                WHEN c14.planta IN ('PB', 'AP', 'AT') THEN c14.superficie_total_efectos_catastro_m2 * 0.5
                ELSE c14.superficie_total_efectos_catastro_m2 
            END) AS sup_total_ajustada
        FROM "{0}".cat_14 AS c14
        JOIN "{0}".building_plus AS b   -- Aquí se especifica el esquema cadastre_input y la tabla dinámica
            ON b.refcat = c14.parcela_catastral
        JOIN "{0}".building_part_plus AS bp 
            ON bp.refcat = b.refcat
        WHERE c14.grup = 'residencial'
        AND c14.superficie_total_efectos_catastro_m2 > 0
        AND c14.planta NOT IN ('AL', 'PK', 'SM', 'PT', 'PL', 'RS', 'PTA')
        GROUP BY b.refcat, bp.numberoffloorsaboveground;
        """.format(self.schema, self.cod_muni)

        
        # Ejecutar la consulta de cálculo
        status, msg = self.execute_sql(sql_residential_surface)
        if not status:
            log_warning(f"Error calculando la superficie residencial: {msg}")
            return False
        
        log_info("Cálculo de superficie residencial completado.")
        return True
            
 
                
    def distribute_residential_surface(self):
        """ Distribuir la superficie residencial calculada por las plantas de los edificios """
        
        log_info("Distribuyendo superficie residencial...")
        
        sql_distribute_surface = """
        -- Actualizar las superficies residenciales distribuidas
        ALTER TABLE "{0}".building_part_planta_juntes ADD COLUMN IF NOT EXISTS sup_residencial_distribuida NUMERIC(10,2);
        UPDATE "{0}".building_part_planta_juntes AS b
        SET sup_residencial_distribuida = t.sup_total_ajustada / NULLIF(t.num_plantas, 0)
        FROM "{0}".temp_superficie_residencial AS t
        WHERE b.refcat = t.refcat;
        """.format(self.schema)
        
        # Ejecutar la distribución de superficies
        status, msg = self.execute_sql(sql_distribute_surface)
        if not status:
            log_warning(f"Error distribuyendo la superficie residencial: {msg}")
            return False
        
        log_info("Distribución de superficie residencial completada.")
        return True











*/


