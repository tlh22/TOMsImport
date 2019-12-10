# -*- coding: utf-8 -*-
"""
/***************************************************************************
 ImportWandsworth2
                                 A QGIS plugin
 cc
 Generated by Plugin Builder: http://g-sherman.github.io/Qgis-Plugin-Builder/
                              -------------------
        begin                : 2019-12-07
        git sha              : $Format:%H$
        copyright            : (C) 2019 by th
        email                : th
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""
from PyQt5.QtCore import QSettings, QTranslator, qVersion, QCoreApplication
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtWidgets import QAction, QMessageBox

from qgis.PyQt.QtCore import (
    QObject,
    QTimer,
    pyqtSignal,
    QSettings, QTranslator, qVersion, QCoreApplication
)

from qgis.core import (
    QgsExpressionContextUtils,
    QgsExpression,
    QgsFeatureRequest,
    # QgsMapLayerRegistry,
    QgsMessageLog, QgsFeature, QgsGeometry,
    QgsTransaction, QgsTransactionGroup,
    QgsProject,
    QgsVectorFileWriter,
    QgsApplication,
    QgsVectorLayer,
    QgsFields, QgsDataSourceUri, QgsWkbTypes
)

from qgis.gui import QgsFileWidget, QgsMapLayerComboBox

# Initialize Qt resources from file resources.py
from .resources import *
# Import the code for the dialog
from .import_wandsworth_dialog import ImportWandsworth2Dialog
import os.path
import time
import datetime

from .importPolygon import importPolygon
from .importMatchLists import (
    matchLists
)
class ImportWandsworth2:
    """QGIS Plugin Implementation."""

    def __init__(self, iface):
        """Constructor.

        :param iface: An interface instance that will be passed to this class
            which provides the hook by which you can manipulate the QGIS
            application at run time.
        :type iface: QgsInterface
        """
        # Save reference to the QGIS interface
        self.iface = iface
        # initialize plugin directory
        self.plugin_dir = os.path.dirname(__file__)
        # initialize locale
        locale = QSettings().value('locale/userLocale')[0:2]
        locale_path = os.path.join(
            self.plugin_dir,
            'i18n',
            'ImportWandsworth2_{}.qm'.format(locale))

        if os.path.exists(locale_path):
            self.translator = QTranslator()
            self.translator.load(locale_path)

            if qVersion() > '4.3.3':
                QCoreApplication.installTranslator(self.translator)

        # Declare instance attributes
        self.actions = []
        self.menu = self.tr(u'&Import Wandsworth')

        # Set up log file and collect any relevant messages
        logFilePath = os.environ.get('QGIS_LOGFILE_PATH')

        if logFilePath:

            QgsMessageLog.logMessage("LogFilePath: " + str(logFilePath), tag="TOMs panel")

            logfile = 'qgis_' + datetime.date.today().strftime("%Y%m%d") + '.log'
            self.filename = os.path.join(logFilePath, logfile)
            QgsMessageLog.logMessage("Sorting out log file" + self.filename, tag="TOMs panel")
            QgsApplication.instance().messageLog().messageReceived.connect(self.write_log_message)

        # Check if plugin was started the first time in current QGIS session
        # Must be set in initGui() to survive plugin reloads
        self.first_start = None

    def write_log_message(self, message, tag, level):
        # filename = os.path.join('C:\Users\Tim\Documents\MHTC', 'qgis.log')
        with open(self.filename, 'a') as logfile:
            logfile.write('{dateDetails}:: {message}\n'.format(dateDetails= time.strftime("%Y%m%d:%H%M%S"), message=message))

    # noinspection PyMethodMayBeStatic
    def tr(self, message):
        """Get the translation for a string using Qt translation API.

        We implement this ourselves since we do not inherit QObject.

        :param message: String for translation.
        :type message: str, QString

        :returns: Translated version of message.
        :rtype: QString
        """
        # noinspection PyTypeChecker,PyArgumentList,PyCallByClass
        return QCoreApplication.translate('ImportWandsworth2', message)


    def add_action(
        self,
        icon_path,
        text,
        callback,
        enabled_flag=True,
        add_to_menu=True,
        add_to_toolbar=True,
        status_tip=None,
        whats_this=None,
        parent=None):
        """Add a toolbar icon to the toolbar.

        :param icon_path: Path to the icon for this action. Can be a resource
            path (e.g. ':/plugins/foo/bar.png') or a normal file system path.
        :type icon_path: str

        :param text: Text that should be shown in menu items for this action.
        :type text: str

        :param callback: Function to be called when the action is triggered.
        :type callback: function

        :param enabled_flag: A flag indicating if the action should be enabled
            by default. Defaults to True.
        :type enabled_flag: bool

        :param add_to_menu: Flag indicating whether the action should also
            be added to the menu. Defaults to True.
        :type add_to_menu: bool

        :param add_to_toolbar: Flag indicating whether the action should also
            be added to the toolbar. Defaults to True.
        :type add_to_toolbar: bool

        :param status_tip: Optional text to show in a popup when mouse pointer
            hovers over the action.
        :type status_tip: str

        :param parent: Parent widget for the new action. Defaults None.
        :type parent: QWidget

        :param whats_this: Optional text to show in the status bar when the
            mouse pointer hovers over the action.

        :returns: The action that was created. Note that the action is also
            added to self.actions list.
        :rtype: QAction
        """

        icon = QIcon(icon_path)
        action = QAction(icon, text, parent)
        action.triggered.connect(callback)
        action.setEnabled(enabled_flag)

        if status_tip is not None:
            action.setStatusTip(status_tip)

        if whats_this is not None:
            action.setWhatsThis(whats_this)

        if add_to_toolbar:
            # Adds plugin icon to Plugins toolbar
            self.iface.addToolBarIcon(action)

        if add_to_menu:
            self.iface.addPluginToMenu(
                self.menu,
                action)

        self.actions.append(action)

        return action

    def initGui(self):
        """Create the menu entries and toolbar icons inside the QGIS GUI."""

        icon_path = ':/plugins/import_wandsworth/icon.png'
        self.add_action(
            icon_path,
            text=self.tr(u'Import Wandsworth'),
            callback=self.run,
            parent=self.iface.mainWindow())

        # will be set False in run()
        self.first_start = True


    def unload(self):
        """Removes the plugin menu item and icon from QGIS GUI."""
        for action in self.actions:
            self.iface.removePluginMenu(
                self.tr(u'&Import Wandsworth'),
                action)
            self.iface.removeToolBarIcon(action)


    def run(self):
        """Run method that performs all the real work"""

        # Create the dialog with elements (after translation) and keep reference
        # Only create GUI ONCE in callback, so that it will only load when the plugin is started
        if self.first_start == True:
            self.first_start = False
            self.dlg = ImportWandsworth2Dialog()

        cb_importPolygonLayer = self.dlg.findChild(QgsMapLayerComboBox, "importPolygonLayer")
        cb_snapLayer = self.dlg.findChild(QgsMapLayerComboBox, "snapLayer")
        cb_outputLayer = self.dlg.findChild(QgsMapLayerComboBox, "outputLayer")

        # show the dialog
        self.dlg.show()
        # Run the dialog event loop
        result = self.dlg.exec_()
        # See if OK was pressed
        if result:
            # Do something useful here - delete the line containing pass and
            # substitute with your code.
            """ dialog will give layer to consider and trace line

            Need to:
             - loop through each point. 
              - if point is within tolerance of the """

            importPolygonLayer = cb_importPolygonLayer.currentLayer()
            snapLayer = cb_snapLayer.currentLayer()
            outputLayer = cb_outputLayer.currentLayer()

            if self.dlg.fld_Tolerance.text():
                tolerance = float(self.dlg.fld_Tolerance.text())
            else:
                tolerance = 0.5
            QgsMessageLog.logMessage("Tolerance = " + str(tolerance), tag="TOMs panel")

            QgsMessageLog.logMessage("importPolygonLayer is ..." + str(importPolygonLayer.name()), tag="TOMs panel")

            res = self.generateLinesFromPolygons(importPolygonLayer, snapLayer, outputLayer, tolerance)

    def generateLinesFromPolygons(self, polygonLayer, snapLineLayer, outputLayer, tolerance):

        QgsMessageLog.logMessage("In snapNodes", tag="TOMs panel")

        editStartStatus = outputLayer.startEditing()

        reply = QMessageBox.information(None, "Check",
                                        "SnapNodes: Status for starting edit session on " + outputLayer.name() + " is: " + str(
                                            editStartStatus),
                                        QMessageBox.Ok)

        if editStartStatus is False:
            # save the active layer
            QgsMessageLog.logMessage("Error: snapNodesP: Not able to start transaction on " + outputLayer.name())
            reply = QMessageBox.information(None, "Error",
                                            "SnapNodes: Not able to start transaction on " + outputLayer.name(),
                                            QMessageBox.Ok)
            return
        # Snap node to nearest point

        for currFeature in polygonLayer.getFeatures():
            ptsList = importPolygon(currFeature).getListPointsInPolygonWithinTolerance(snapLineLayer, tolerance)
            if len(ptsList) < 2:
                continue
            newLine = QgsGeometry.fromPolylineXY(ptsList)

            fields = outputLayer.fields()
            new_feat = QgsFeature(fields)

            """ somehow neeed to add attributes ... """
            self.copyAttributesFromList(new_feat, outputLayer, currFeature, polygonLayer, matchLists.baysMatchList)

            new_feat.setGeometry(newLine)
            outputLayer.addFeature(new_feat)

        editCommitStatus = outputLayer.commitChanges()

        """reply = QMessageBox.information(None, "Check",
                                        "SnapNodes: Status for commit to " + sourceLineLayer.name() + " is: " + str(
                                            editCommitStatus),
                                        QMessageBox.Ok)"""

        if editCommitStatus is False:
            # save the active layer
            QgsMessageLog.logMessage("Error: snapNodesP: Changes to " + outputLayer.name() + " failed: " + str(
                outputLayer.commitErrors()))
            reply = QMessageBox.information(None, "Error",
                                            "SnapNodes: Changes to " + outputLayer.name() + " failed: " + str(
                                                outputLayer.commitErrors()),
                                            QMessageBox.Ok)

        return

    def copyAttributesFromList(self, newFeature, newFeatureLayer, oldFeature, oldFeatureLayer, matchList):

        oldFields = oldFeatureLayer.fields()

        """ Loop though each of the fields in the new feature ..."""
        for oldField in oldFields:

            # QgsMessageLog.logMessage("In copyBayAttributes. field: " + newField.name(), tag="TOMs panel")

            """ Check to see if the field is to be copied """
            for (oldFieldName, newFieldName) in matchList:
                if oldField.name() == oldFieldName:
                    # QgsMessageLog.logMessage("In copyBayAttributes. setting field: " + newField.name(), tag="TOMs panel")
                    newFeature.setAttribute(newFieldName, oldFeature.attribute(oldFieldName))