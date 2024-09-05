# -*- coding: utf-8 -*-
import os
from qgis.PyQt import uic
from qgis.PyQt import QtWidgets

FORM_CLASS, _ = uic.loadUiType(os.path.join(os.path.dirname(__file__), 'dlg_suno.ui'))


class DlgSuno(QtWidgets.QDialog, FORM_CLASS):
    def __init__(self, parent=None):
        super(DlgSuno, self).__init__(parent)
        self.setupUi(self)