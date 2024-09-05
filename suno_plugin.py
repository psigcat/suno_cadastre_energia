# -*- coding: utf-8 -*-
from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtWidgets import QAction, QListWidgetItem
from qgis.core import QgsVectorLayer, QgsApplication

import os

from .ui.suno_dialog import DlgSuno
from .suno_utils import get_metadata_parameter, show_info, show_warning, log_info
from .suno_task import SunoTask


class SunoCadastre:

    def __init__(self, iface):

        self.iface = iface
        self.plugin_dir = os.path.dirname(__file__)
        self.actions = []
        self.menu = 'Suno Cadastre'
        self.dlg = None
        self.suno_task = None
        self.db_status = None


    def initGui(self):

        icon_path = os.path.join(self.plugin_dir, 'img', 'suno.png')
        self.add_action(icon_path, text='Obrir formulari', callback=self.open_dialog, parent=self.iface.mainWindow())

        # Guardar el diàleg en una variable de classe
        self.dlg = DlgSuno()
        flags = Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint
        self.dlg.setWindowFlags(self.dlg.windowFlags() | flags)
        self.set_signals()

        # Get parameters from metadata
        version = get_metadata_parameter(self.plugin_dir)
        self.dlg.setWindowTitle(f"Suno versió {version}")
        log_info(f"Versió {version}")
        self.output_folder = get_metadata_parameter(self.plugin_dir, "app", "output_folder")
        if self.output_folder is None:
            self.output_folder = os.path.join(self.plugin_dir, "output")
        self.dlg.output_folder.setFilePath(self.output_folder)             


    def unload(self):
        """ Removes the plugin menu item and icon from QGIS GUI """
        for action in self.actions:
            self.iface.removePluginMenu('Suno Cadastre', action)
            self.iface.removeToolBarIcon(action)


    def add_action(self, icon_path, text, callback, parent=None, add_to_menu=True, add_to_toolbar=True):

        icon = QIcon(icon_path)
        action = QAction(icon, text, parent)
        action.triggered.connect(callback)
        action.setEnabled(True)
        if add_to_toolbar:
            self.iface.addToolBarIcon(action)
        if add_to_menu:
            self.iface.addPluginToMenu(self.menu, action)
        self.actions.append(action)
        return action


    def set_signals(self):

        self.dlg.btn_test_db.clicked.connect(self.test_db)
        self.dlg.btn_get_munis.clicked.connect(self.get_munis)
        self.dlg.btn_accept.clicked.connect(self.get_selected_muni)
        self.dlg.list_munis.doubleClicked.connect(self.get_selected_muni)


    def open_dialog(self):
        self.dlg.show()


    def test_db(self):
        suno_task = SunoTask("08001")         
        self.db_status = suno_task.init_db()


    def get_munis(self):
        """ Obtenir llistat dels municipis seleccionats """

        field_code = "cod_ine"
        field_name = "nom_ine"
        self.dlg.list_munis.clear()
        active_layer: QgsVectorLayer = self.iface.activeLayer()
        if active_layer is None:
            show_warning("Cal seleccionar alguna capa")
            return
        features_it = active_layer.getSelectedFeatures()
        features = [feature for feature in features_it]
        if len(features) == 0:
            show_warning("Cal seleccionar algun registre")
            return
        for feature in features:
            if field_code not in feature.fields().names():
                show_warning(f"No existeix camp codi del municipi: '{field_code}")
                return            
            cod_muni = feature[field_code]
            nom_muni = feature[field_name]
            item = QListWidgetItem()
            item.setText(f"{cod_muni} - {nom_muni}")
            self.dlg.list_munis.addItem(item)
    
    
    def get_selected_muni(self):
        """ Obtenir registre seleccionat en el llistat """

        selected_item = self.dlg.list_munis.currentItem()
        if selected_item is None:
            show_info("Cal seleccionar algun municipi a executar")
            return
        
        cod_muni = selected_item.text().split('-')[0].strip()
        self.exec_main_process(cod_muni)
    
    
    def exec_main_process(self, cod_muni):

        description = f"Processant municipi: {cod_muni}"
        log_info(description)
        self.dlg.close()
        self.suno_task = SunoTask(cod_muni, description)            
        self.db_status = self.suno_task.init_db()
        if self.db_status:
            QgsApplication.taskManager().addTask(self.suno_task)

