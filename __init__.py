# -*- coding: utf-8 -*-
def classFactory(iface):

    from .suno_plugin import SunoCadastre
    return SunoCadastre(iface)
