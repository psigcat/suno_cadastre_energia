# -*- coding: utf-8 -*-
from qgis.PyQt.QtSql import QSqlDatabase
from qgis.core import QgsProject, QgsDataSourceUri, QgsVectorLayer, QgsRasterLayer, QgsApplication
import processing

import os
import psycopg2
import subprocess

try:
    from .suno_utils import get_metadata_parameter, show_info, show_warning
except:
    from suno_utils import get_metadata_parameter, show_info, show_warning


class SunoProcess:

    def __init__(self):

        self.plugin_dir = os.path.dirname(__file__)
        self.service: str = None
        self.schema: str = None
        self.cod_muni = None
        self.sql_folder = None
        self.output_folder = None


    def init_db(self):
        """ Connect to database """

        service_name = get_metadata_parameter(self.plugin_dir, "app", "service")
        self.service = service_name
        status = self.connect_db(service_name)
        if not status:
            return False
        return True


    def connect_db(self, service_name):

        try:
            self.conn = psycopg2.connect(service=service_name)
            self.cursor = self.conn.cursor()
            show_info(f"Connexió correcta al servei de Base de Dades '{service_name}'")
            return True
        except (Exception) as e:
            show_warning(f"Connexió errònia al servei de Base de Dades '{service_name}': {e}")
            return False


    def init_main(self, cod_muni=False):

        if cod_muni is False:
            show_info("Obtenint codi municipi del paràmetre 'cod_muni'")
            self.cod_muni = get_metadata_parameter(self.plugin_dir, "app", "cod_muni")
        else:
            self.cod_muni = cod_muni
        self.schema = f"e{self.cod_muni}"
        self.sql_folder = os.path.join(self.plugin_dir, "sql") 
        self.output_folder = get_metadata_parameter(self.plugin_dir, "app", "output_folder")
        if self.output_folder is None:
            self.output_folder = os.path.join(self.plugin_dir, "output") 
        if not os.path.exists(self.output_folder):
            os.makedirs(self.output_folder)


    def exec_main(self):
        """ Procés principal execució per a un municipi """

        if not self.exec_sql_files(self.cod_muni):
            return

        # Calcular procés "Zonal statistics" per calcular valors "Z"
        show_info("Executant procés 'Estadístiques zonals' per calcular elevacions...")
        z_tablename = self.exec_zonal_stats()
        if not self.table_exists(z_tablename):
            show_warning(f"No existeix la taula '{z_tablename}'")
            return

        # Calcular número de plantes
        num_plantes = self.calculate_num_plantes()

        # Processar fitxer genèric de "plantes"
        filename = "12_create_table_building_part_planta_.sql"
        if not self.process_planta_file(filename, num_plantes):
            return
        
        show_info("Eliminant valors nuls...")
        filename = "13_remove_nulls.sql"
        if not self.process_planta_file(filename, num_plantes):
            return

        show_info("Processant fitxer plantes juntes...")
        filename = "14_create_table_building_part_planta_juntes.sql"
        status, msg = self.process_file(self.sql_folder, filename)
        if not status:
            show_warning(f"Error executant script '{filename}':\n{msg}")
            self.conn.rollback()
            return 
        
        # Guardar canvis
        self.conn.commit()

        # Exportar taules de plantes a fitxers GeoJSON
        ogr2ogr = self.get_ogr2ogr()
        if ogr2ogr is None:
            show_warning("Problemes al configurar 'ogr2ogr'")
            return
        
        # Definim carpeta de sortida per al municipi        
        self.output_folder = os.path.join(self.output_folder, self.cod_muni) 
        if not os.path.exists(self.output_folder):
            os.makedirs(self.output_folder)        
        show_info(f"Generant fitxers de sortida a la carpeta: {self.output_folder}")
        for planta in range(num_plantes + 1):
            planta = str(planta).zfill(2)
            self.export_to_geojson(ogr2ogr, planta)

        self.export_to_geojson(ogr2ogr, "juntes")

        show_info("Procés finalitzat")


    def calculate_num_plantes(self):
        """ Obtenir número de plantes del paràmetre 'num_plantes' """

        num_plantes = 8
        try:
            num_plantes = get_metadata_parameter(self.plugin_dir, "app", "num_plantes")
        except Exception as e:
            show_warning(str(e))
        finally:
            return num_plantes
    
    
    def exec_sql_files(self, cod_muni=None):
        """ Llegir i executar contingut fitxers SQL """

        if cod_muni is None or cod_muni is False:
            show_info("Obtenint valor del paràmetre 'cod_muni'")
        else:
            self.cod_muni = str(cod_muni)

        self.schema = f"e{self.cod_muni}"
        show_info(f"Es generarà esquema: '{self.schema}'")

        # Processar primers fitxers (abans de les plantes)
        if not self.process_first_files(self.sql_folder):
            return False
        
        return True


    def process_first_files(self, folderpath):

        NUM_SQL_FILES = 7
        status = False
        sql_files = self.get_sql_files(folderpath)
        sql_files = sql_files[:NUM_SQL_FILES]
        for filename in sql_files:
            status, msg = self.process_file(folderpath, filename)
            if not status:
                show_warning(f"Error executant script '{filename}':\n{msg}")
                self.conn.rollback()
                return False
            
        self.conn.commit()            
        return True
    
    
    def process_planta_file(self, filename, num_plantes=8):

        for planta in range(num_plantes + 1):
            planta = str(planta).zfill(2)
            status, msg = self.process_file(self.sql_folder, filename, planta)
            if not status:
                show_warning(f"Error executant script '{filename}':\n{msg}")
                self.conn.rollback()
                return False
        
        return True
    
    
    def process_file(self, folderpath, filename, planta=None):

        filepath = os.path.join(folderpath, filename)
        if planta is None:
            show_info(f"Executant fitxer: {filename}")
        else:
            show_info(f"Executant planta: '{planta}'")
        with open(filepath, 'r') as file:
            sql = file.read()

        # Substituir paràmetres: [SCHEMA_NAME], [COD_MUNI], [TABLE_BUILDING], [TABLE_BUILDING_PART]
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
            sql = sql.replace('[ALTURA]', f'{altura}')
            sql = sql.replace('[C14_PLANTA]', c14_planta)
        status, msg = self.execute_sql(sql, commit=False)
        return status, msg
    
    
    def get_sql_files(self, folderpath, search_text=None):

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

        data_source = QgsDataSourceUri()
        data_source.setParam("service", service)
        data_source.setDataSource(schema, table, geom_field)
        layer = QgsVectorLayer(data_source.uri(), table, "postgres")
        if not layer.isValid():
            show_warning(f"Error obtenint la capa vectorial '{schema}.{table}'")
            return None

        if add_layer:
            QgsProject.instance().addMapLayer(layer)
        return layer
    

    def get_raster_from_postgis(self, service, schema, table, raster_field="rast", add_layer=False):

        data_source = QgsDataSourceUri()
        data_source.setParam("service", service)
        data_source.setDataSource(schema, table, raster_field)
        layer = QgsRasterLayer(data_source.uri(), table, "postgresraster")
        if not layer.isValid():
            show_warning(f"Error obtenint la capa ràster '{schema}.{table}'")
            return None

        if add_layer:
            QgsProject.instance().addMapLayer(layer)
        return layer


    def exec_zonal_stats(self):
        """ Executar procés "Zonal statistics" 
            Crea taula 'building_part_plus_z'
        """

        tablename = "building_part_plus"
        z_tablename = f"{self.schema}.{tablename}_z"
        input_polygon = self.get_vector_from_postgis(self.service, self.schema, tablename)
        input_raster = self.get_raster_from_postgis(self.service, "raster", "mde_cat_30m")
        if input_polygon is None or input_raster is None:
            return
        
        output = f'postgres://service=\'{self.service}\' sslmode=disable table="{self.schema}"."{tablename}_z" (geom)'
        params = {
            'COLUMN_PREFIX': 'z_', 
            'INPUT': input_polygon, 
            'INPUT_RASTER': input_raster, 
            'OUTPUT': output, 
            'RASTER_BAND': 1, 
            'STATISTICS': [2,5,6] 
        }

        try:
            show_info("Executant procés 'zonalstatisticsfb'...")
            result = processing.run('native:zonalstatisticsfb', params)
            show_info("Fi procés 'zonalstatisticsfb'")
            layer_result = result['OUTPUT']
            #QgsProject.instance().addMapLayer(layer_result)
            return z_tablename
        except Exception as e:
            show_warning(str(e))
            return False
        

    def get_ogr2ogr(self):
        """ Definir ruta a executable 'ogr2ogr' """
        
        qgis_folder = os.path.dirname(os.path.dirname(QgsApplication.prefixPath()))
        if not os.path.exists(qgis_folder):
            show_warning(f"Carpeta de QGIS no trobada: {qgis_folder}")
            qgis_folder = r"C:\Program Files\QGIS 3.28.4"
            if not os.path.exists(qgis_folder):
                show_warning(f"Carpeta de QGIS no trobada: {qgis_folder}")            
                return None

        ogr2ogr = os.path.join(qgis_folder, 'bin', 'ogr2ogr.exe')
        if not os.path.exists(ogr2ogr):
            show_warning(f"Executable 'ogr2ogr' no trobat: {ogr2ogr}")
            return None
        
        return ogr2ogr


    def export_to_geojson(self, ogr2ogr, planta):
        """ Exportar taula de la planta a fitxer GeoJSON """

        # Definir opcions i connexió a Postgres
        options = '-a_srs EPSG:25831 -skipfailures'
        pg = f'PG:"service={self.service}"'

        # Definir fitxer GeoJSON a generar
        json_file = os.path.join(self.output_folder, f'planta_{planta}.geojson')
        if os.path.exists(json_file):
            os.remove(json_file)
        
        # Comanda a executar
        tablename = f'building_part_planta_{planta}'
        cmd = f'"{ogr2ogr}" -f GeoJSON {options} "{json_file}" {pg} {self.schema}.{tablename}'
        show_info(cmd)
        subprocess.run(cmd, check=True)


    def table_exists(self, tablename):

        sql = f"SELECT * FROM pg_tables WHERE schemaname = '{self.schema}' AND tablename = '{tablename}'"
        cursor = self.conn.cursor()
        cursor.execute(sql)
        row = cursor.fetchone()
        if row:
            return True
        else:
            return False
        
