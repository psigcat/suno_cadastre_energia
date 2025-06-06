# -*- coding: utf-8 -*-
from qgis.core import QgsProject, QgsDataSourceUri, QgsVectorLayer, QgsRasterLayer, QgsApplication, QgsTask
import processing

import os
import psycopg2
import subprocess
import time

try:
    from .suno_utils import get_metadata_parameter, show_info, show_warning, log_info, log_warning
except:
    from suno_utils import get_metadata_parameter, show_info, show_warning, log_info, log_warning


class SunoTask(QgsTask):

    def __init__(self, cod_muni, description="Processant municipi..."):

        super().__init__(description, QgsTask.CanCancel)
        self._is_canceled = False
        self.cod_muni = cod_muni
        self.plugin_dir = os.path.dirname(__file__)
        self.service: str = None
        self.schema: str = None
        self.sql_folder = None
        self.output_folder = None        

  
    def run(self):

        self.start_time = time.time()
        self.init_main()
        return self.exec_main()

    
    def finished(self, result):

        end_time = time.time()
        duration = end_time - self.start_time
        try:
            if result:
                show_info("Procés finalitzat")
            else:
                if self._is_canceled:
                    show_info("Procés cancelat")
                else:
                    show_warning("Error executant el procés")
                self.conn.rollback()
            log_info(f"Duració: {duration:.2f} segons")
        except Exception as e:
            show_warning(f"Error inesperat: {e}")


    def cancel(self):

        super().cancel()

    
    def init_db(self):
        """ Obtenir nom del servei i connectar a la Base de Dades """

        service_name = get_metadata_parameter(self.plugin_dir, "app", "service")
        self.service = service_name
        status = self.connect_db(service_name)
        if not status:
            return False
        return True


    def connect_db(self, service_name):
        """ Connectar a la Base de Dades usant nom del servei especificat """

        try:
            self.conn = psycopg2.connect(service=service_name)
            self.cursor = self.conn.cursor()
            log_info(f"Connexió correcta al servei de Base de Dades '{service_name}'")
            return True
        except Exception as e:
            log_warning(f"Connexió errònia al servei de Base de Dades '{service_name}': {e}")
            return False


    def init_main(self):
        """ Inicialització del procés """

        schema_prefix = get_metadata_parameter(self.plugin_dir, "app", "schema_prefix")
        if schema_prefix is None:
            schema_prefix = "e"
        if self.cod_muni is None:
            self.cod_muni = get_metadata_parameter(self.plugin_dir, "app", "cod_muni")
        self.schema = f"{schema_prefix}{self.cod_muni}"
        self.sql_folder = os.path.join(self.plugin_dir, "sql") 
        self.output_folder = get_metadata_parameter(self.plugin_dir, "app", "output_folder")
        if self.output_folder is None:
            self.output_folder = os.path.join(self.plugin_dir, "output") 
        if not os.path.exists(self.output_folder):
            os.makedirs(self.output_folder)


    def exec_main(self):
        """ Procés principal execució per a un municipi """

        log_info(f"Es generarà esquema: '{self.schema}'")
        if not self.exec_sql_files(self.cod_muni):
            return False

        # Cal commitejar canvis per tal de poder executar 'Zonal statistics'
        self.conn.commit()

        # Calcular procés "Zonal statistics" per calcular valors "Z"
        log_info("Executant procés 'Estadístiques zonals' per calcular elevacions...")
        z_tablename = self.exec_zonal_stats()
        if not z_tablename:
            log_warning(f"Error executant procés 'Estadístiques zonals'")
            return False
        if z_tablename and not self.table_exists(z_tablename):
            log_warning(f"No existeix la taula '{z_tablename}'")
            return False

        # Calcular número de plantes
        filename = "12_get_num_plantes.sql"
        num_plantes = self.calculate_num_plantes(self.sql_folder, filename)
        log_info(f"Número total de plantes: {num_plantes}")

        # Processar fitxer genèric de "plantes"
        filename = "14_create_table_building_part_planta_.sql"
        log_info(f"Executant fitxer de plantes. Número de plantes: '{num_plantes}'")
        if not self.process_planta_file(filename, 0, num_plantes):
            return False
        
        # Creant taula 'building_part_planta_juntes'
        log_info("Creant taula 'building_part_planta_juntes'")
        filename = "20_create_table_building_part_planta_juntes.sql"
        status, msg = self.process_file(self.sql_folder, filename)
        if not status:
            log_warning(f"Error executant script '{filename}':\n{msg}")
            return False
        
        # Insertant dades de cada planta
        filename = "22_insert_into_building_part_planta_juntes.sql"
        log_info(f"Insertant dades de cada planta")
        if not self.process_planta_file(filename, 1, num_plantes):
            return False
        
        # Gestió àtics
        self.set_obtencio_us()
        self.manage_atics()
                   

   
   
        # Afegim les noves funcions per calcular i distribuïr la superfície residencial
        
        ## self.calculate_residential_surface()    
        ## self.distribute_residential_surface()                
        
        log_info(f"Executant càlculs suma i distribució superfície residencial")
        filename = "23_create_temp_superficie_residencial.sql"
        status, msg = self.process_file(self.sql_folder, filename)
        if not status:
            log_warning(f"Error executant script '{filename}':\n{msg}")
            return False

        # Cal commitejar canvis per tal de poder executar 'ogr2ogr'
        self.conn.commit()

        # Exportar taules de plantes a fitxers GeoJSON
        ogr2ogr = self.get_ogr2ogr()
        if ogr2ogr is None:
            log_warning("Problemes al configurar 'ogr2ogr'")
            return False
        
        # Definim carpeta de sortida per al municipi        
        self.output_folder = os.path.join(self.output_folder, self.cod_muni) 
        if not os.path.exists(self.output_folder):
            os.makedirs(self.output_folder)        

        log_info(f"Generant fitxer de sortida a la carpeta: {self.output_folder}")
        self.export_to_geojson(ogr2ogr, "juntes")

        return True


    def calculate_num_plantes(self, folderpath, filename):
        """ Obtenir número de plantes del paràmetre 'num_plantes' """

        num_plantes = 10
        try:
            filepath = os.path.join(folderpath, filename)
            with open(filepath, 'r') as file:
                sql = file.read()

            # Construir i executar SQL
            sql = self.build_sql(sql)
            cursor = self.conn.cursor()
            cursor.execute(sql)
            row = cursor.fetchone()
            if not row:
                return False
            num_plantes = row[0]
        except Exception as e:
            show_warning(str(e))
        finally:
            return num_plantes
    
    
    def exec_sql_files(self, cod_muni=None):
        """ Llegir i executar contingut fitxers SQL """

        if cod_muni is None or cod_muni is False:
            log_info("Obtenint valor del paràmetre 'cod_muni'")
        else:
            self.cod_muni = str(cod_muni)

        # Processar primers fitxers (abans de les plantes)
        if not self.process_first_files(self.sql_folder):
            return False
        
        return True


    def process_first_files(self, folderpath):
        """ Processar primers fitxers (abans de les plantes) """

        NUM_SQL_FILES = 8
        status = False
        sql_files = self.get_sql_files(folderpath)
        sql_files = sql_files[:NUM_SQL_FILES]
        for filename in sql_files:
            if self.isCanceled():
                self._is_canceled = True
                return False
            status, msg = self.process_file(folderpath, filename)
            if not status:
                log_warning(f"Error executant script '{filename}':\n{msg}")
                self.conn.rollback()
                return False
 
        return True
    
    
    def process_planta_file(self, filename, planta_inicial, num_plantes):

        for planta in range(planta_inicial, num_plantes + 1):
            if self.isCanceled():
                self._is_canceled = True
                return False
            planta = str(planta).zfill(2)
            status, msg = self.process_file(self.sql_folder, filename, planta)
            if not status:
                log_warning(f"Error executant script '{filename}':\n{msg}")
                self.conn.rollback()
                return False
        
        return True
    
    
    def process_file(self, folderpath, filename, planta=None):
        """ Llegir i executar fitxer .sql """

        filepath = os.path.join(folderpath, filename)
        if planta is None:
            log_info(f"Executant fitxer: {filename}")
        with open(filepath, 'r') as file:
            sql = file.read()

        # Construir i executar SQL
        sql = self.build_sql(sql, planta)
        status, msg = self.execute_sql(sql, commit=False)
        return status, msg
    
    
    def build_sql(self, sql, planta=None):
        """ Substituir paràmetres: [SCHEMA_NAME], [COD_MUNI], [TABLE_BUILDING], [TABLE_BUILDING_PART] """
        
        log_info("Substitució paràmetres ... [PLANTA] ")
        sql = sql.replace('[SCHEMA_NAME]', f'"{self.schema}"')
        sql = sql.replace('[COD_MUNI]', f'{self.cod_muni}')
        table_building = f"{self.cod_muni}_building"
        table_building_part = f"{self.cod_muni}_buildingpart"
        sql = sql.replace('[TABLE_BUILDING]', f'"{table_building}"')
        sql = sql.replace('[TABLE_BUILDING_PART]', f'"{table_building_part}"')         
        if planta:
            sql = sql.replace('[PLANTA]', f'{planta}')
            altura = 3.2
            c14_planta = f"'{planta} '"
            if planta == "00":
                altura = 4
                c14_planta = f"'{planta} ', 'BJ ', 'BX '"
            elif planta == "OD":
                c14_planta = "'OD ', 'OT ', 'TR ', 'ALT '"
                # ('AL ', 'SM ', 'OP ') 
                num_planta = 99
            num_planta = int(planta)
            sql = sql.replace('[ALTURA]', f'{altura}')
            sql = sql.replace('[C14_PLANTA]', c14_planta)  
            sql = sql.replace('[NUM_PLANTA]', str(num_planta))  

        return sql   
    
    
    def get_sql_files(self, folderpath, search_text=None):
        """ Obtenir fitxers .sql de la carpeta indicada """

        sql_files = [
            file for file in os.listdir(folderpath) 
            if file.endswith('.sql') and os.path.isfile(os.path.join(folderpath, file)) and (search_text is None or search_text in file)
        ]
        return sql_files    


    def execute_sql(self, sql, commit=True):
        """ Executar consulta SQL """

        msg = None
        cursor = None
        status = True
        try:
            cursor = self.conn.cursor()
            cursor.execute(sql)
            if commit:
                self.conn.commit()
        except Exception as e:
            status = False
            msg = e
            if self.conn:
                self.conn.rollback()
        finally:
            if cursor:
                cursor.close()
            return status, msg
        

    def get_vector_from_postgis(self, service, schema, table, geom_field="geom", add_layer=False):
        """ Crear i retornar capa vectorial amb els paràmetres indicats """

        data_source = QgsDataSourceUri()
        data_source.setParam("service", service)
        data_source.setDataSource(schema, table, geom_field)
        layer = QgsVectorLayer(data_source.uri(), table, "postgres")
        if not layer.isValid():
            log_warning(f"Error obtenint la capa vectorial '{schema}.{table}'")
            return None

        if add_layer:
            QgsProject.instance().addMapLayer(layer)
        return layer
    

    def get_raster_from_postgis(self, service, schema, table, raster_field="rast", add_layer=False):
        """ Crear i retornar capa ràster amb els paràmetres indicats """

        data_source = QgsDataSourceUri()
        data_source.setParam("service", service)
        data_source.setDataSource(schema, table, raster_field)
        layer = QgsRasterLayer(data_source.uri(), table, "postgresraster")
        if not layer.isValid():
            log_warning(f"Error obtenint la capa ràster '{schema}.{table}'")
            return None

        if add_layer:
            QgsProject.instance().addMapLayer(layer)
        return layer


    def exec_zonal_stats(self):
        """ Executar procés "Zonal statistics" -> Crea taula 'building_part_plus_z' """

        tablename = "building_part_plus"
        z_tablename = f"{tablename}_z"
        input_polygon = self.get_vector_from_postgis(self.service, self.schema, tablename)
        input_raster = self.get_raster_from_postgis(self.service, "raster", "mde_cat_30m")
        if input_polygon is None or input_raster is None:
            return False
        
        output = f'postgres://service=\'{self.service}\' sslmode=disable table="{self.schema}"."{z_tablename}" (geom)'
        params = {
            'COLUMN_PREFIX': 'z_', 
            'INPUT': input_polygon, 
            'INPUT_RASTER': input_raster, 
            'OUTPUT': output, 
            'RASTER_BAND': 1, 
            'STATISTICS': [2,5,6] 
        }

        try:
            processing.run('native:zonalstatisticsfb', params)
            if self.isCanceled():
                self._is_canceled = True
                return False
            log_info("Fi procés 'Estadístiques zonals'")
            return z_tablename
        except Exception as e:
            log_warning(str(e))
            return False
        

    def get_ogr2ogr(self):
        """ Definir ruta a executable 'ogr2ogr' """
        
        qgis_folder = os.path.dirname(os.path.dirname(QgsApplication.prefixPath()))
        if not os.path.exists(qgis_folder):
            log_warning(f"Carpeta de QGIS no trobada: {qgis_folder}")
            qgis_folder = r"C:\Program Files\QGIS 3.28.4"
            if not os.path.exists(qgis_folder):
                log_warning(f"Carpeta de QGIS no trobada: {qgis_folder}")            
                return None

        ogr2ogr = os.path.join(qgis_folder, 'bin', 'ogr2ogr.exe')
        if not os.path.exists(ogr2ogr):
            log_warning(f"Executable 'ogr2ogr' no trobat: {ogr2ogr}")
            return None
        
        return ogr2ogr


    def export_to_geojson(self, ogr2ogr, planta):
        """ Exportar taula de la planta a fitxer GeoJSON """

        # Definir opcions i connexió a Postgres
        options = '-t_srs EPSG:4326 -skipfailures'
        pg = f'PG:"service={self.service}"'

        # Definir fitxer GeoJSON a generar
        json_file = os.path.join(self.output_folder, f'planta_{planta}.geojson')
        if os.path.exists(json_file):
            os.remove(json_file)
        
        # Comanda a executar
        tablename = f'building_part_planta_{planta}'
        cmd = f'"{ogr2ogr}" -f GeoJSON {options} "{json_file}" {pg} {self.schema}.{tablename}'
        log_info(cmd)
        subprocess.run(cmd, check=True)


    def table_exists(self, tablename):
        """ Comprova si existeix la taula en l'esquema del municipi """

        sql = f"SELECT * FROM pg_tables WHERE schemaname = '{self.schema}' AND tablename = '{tablename}'"
        cursor = self.conn.cursor()
        cursor.execute(sql)
        row = cursor.fetchone()
        if row:
            return True
        else:
            return False
        

    def set_obtencio_us(self):
        """ Add field to set 'obtenció ús' """

        log_info("Afegir camp 'obtencio_us'")
        obtencio_us = "Segons cat_14"
        cursor = self.conn.cursor()
        sql = f"ALTER TABLE {self.schema}.building_part_planta_juntes ADD COLUMN obtencio_us TEXT;"
        cursor.execute(sql)
        sql = f"UPDATE {self.schema}.building_part_planta_juntes SET obtencio_us = '{obtencio_us}' WHERE us_principal_codi is NOT NULL"
        cursor.execute(sql)
    
    
    def manage_atics(self, num_planta=2):
        """ Funció per omplir dades dels àtics agafant informació de la penúltima planta """

        log_info("Processant àtics...")
        sql = (f"SELECT refcat, num_planta FROM {self.schema}.building_part_planta_juntes "
               f"WHERE us_principal_codi is NULL AND num_planta >= {num_planta} "
               f"ORDER BY refcat, num_planta")
        cursor = self.conn.cursor()
        cursor.execute(sql)
        rows = cursor.fetchall()
        if not rows:
            log_info(f"No s'han trobat resultats en la consulta:\n{sql}")
            return True

        cursor_2 = self.conn.cursor()        
        for row in rows:
            refcat = row[0]
            num_planta_atic = row[1]
            sql = (f"SELECT any_referencia, zona_clima, us_principal_codi, us_principal_nom, area_planta_residencial  "
                   f"FROM {self.schema}.building_part_planta_juntes "
                   f"WHERE refcat = '{refcat}' AND us_principal_codi is NOT NULL "
                   f"ORDER BY num_planta DESC LIMIT 1")
            cursor_2.execute(sql)
            row_2 = cursor_2.fetchone()
            if row_2:
                any_referencia = row_2[0]
                zona_clima = row_2[1]                
                us_principal_codi = row_2[2]
                us_principal_nom = row_2[3]
                area_planta_residencial = row_2[4]
                obtencio_us = "Estimat planta inferior"
                sql = (f"UPDATE {self.schema}.building_part_planta_juntes "
                       f"SET any_referencia = {any_referencia}, zona_clima = '{zona_clima}', "
                       f"us_principal_codi = '{us_principal_codi}', us_principal_nom = '{us_principal_nom}', "
                       f"area_planta_residencial = {area_planta_residencial}, obtencio_us = '{obtencio_us}' "
                       f"WHERE refcat = '{refcat}' AND num_planta = {num_planta_atic}")
                cursor_2.execute(sql)

        return True

