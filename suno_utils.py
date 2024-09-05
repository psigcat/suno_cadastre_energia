from qgis.core import QgsMessageLog, Qgis
from qgis.utils import iface
from qgis.PyQt.QtWidgets import QLabel, QPlainTextEdit

import os
import configparser

status_widget: QLabel = None
log_widget: QPlainTextEdit = None


def set_widgets(_status_widget, _log_widget):
    global status_widget, log_widget
    status_widget = _status_widget
    log_widget = _log_widget


def get_metadata_parameter(folder, section="general", parameter="version", file="metadata.txt"):
    """ Get parameter value from Metadata """

    # Check if metadata file exists
    metadata_file = os.path.join(folder, file)
    if not os.path.exists(metadata_file):
        show_warning(f"No s'ha trobat l'arxiu de metadades: {metadata_file}")
        return None

    value = None
    try:
        metadata = configparser.ConfigParser()
        metadata.read(metadata_file)
        value = metadata.get(section, parameter)
    except Exception as e:
        show_warning(e)
    finally:
        return value


def show_info(text, message_level=0, duration=10, title="", show_status=True):
    """ Show information message """
    print(f"[INFO] {text}")
    log_info(text)
    if iface:
        iface.messageBar().pushMessage(title, text, message_level, duration)


def show_warning(text, message_level=1, duration=10, title="", show_status=True):
    """ Show warning message """
    print(f"[WARNING] {text}")
    log_warning(text)
    if iface:
        iface.messageBar().pushMessage(title, text, message_level, duration)


def log_info(text, tab_name='Suno'):
    QgsMessageLog.logMessage(text, tab_name, Qgis.Info)


def log_warning(text, tab_name='Suno'):
    QgsMessageLog.logMessage(text, tab_name, Qgis.Warning)

