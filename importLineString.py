#-----------------------------------------------------------
# Licensed under the terms of GNU GPL 2
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#---------------------------------------------------------------------
# Tim Hancock 2019

from qgis.PyQt.QtCore import (
    QObject,
    QDate,
    pyqtSignal
)

from qgis.PyQt.QtWidgets import (
    QMessageBox,
    QAction
)

from qgis.core import (
    QgsMessageLog, QgsFeature, QgsGeometry,
    QgsFeatureRequest,
    QgsRectangle, QgsPointXY, QgsWkbTypes
)

from abc import ABCMeta, abstractstaticmethod
import math

from .snapTraceUtilsMixin import snapTraceUtilsMixin
from TOMs.core.TOMsMessageLog import TOMsMessageLog

#class importLineString(QObject, snapTraceUtilsMixin):
class restrictionToImport(QObject, snapTraceUtilsMixin):

    def __init__(self, currFeature):
        super().__init__()

        QgsMessageLog.logMessage("In importLineString: " + str(currFeature.id()), tag="TOMs panel")

        self.currFeature = currFeature
        self.currGeometry = currFeature.geometry()

        # TODO: change this around
        if not tolerance:
            tolerance = 0.5
        self.tolerance = tolerance

    def setTraceLineLayer(self, traceLineLayer):
        self.traceLineLayer = traceLineLayer

    def setTolerance(self, tolerance):
        self.tolerance = tolerance

    def setAttributeFieldsMatchList(self, matchDetails):
        self.matchDetails = matchDetails

    def getElementGeometry(self):
        pass

    def identifyShapeType(self):
        pass

    def prepareTOMsRestriction(self):
        # function to generate geometry and copy attributes for given feature

        # check feature type - based on "RestrictionTypeID"
        if self.currFeature.attribute("RetrictionTypeID") < 200:
            new_geom = self.reduceBayShape()
        else:
            new_geom = self.reduceLineShape()

        newRestriction = QgsFeature(self.currFeature.fields())
        newRestriction.setGeometry(new_geom)
        #self.copyAttributesFromList(newRestriction, matchLists.baysMatchList)

        return newRestriction

    def reduceLineShape(self):
        # assume that points follow line - use snap/trace
        pass

    def reduceBayShape(self):

        # check start/end points are within tolerance of the tracing line (typically kerb)

        # check if start/end points are the same. Likely to be a rectangle ...

        # check whether or not echelon ...

        # now loop through each of the vertices and process as required. New geometry points are added to ptsList

        """
        Logic is :

        For vertex 0,
            Move for defined distance (typically 0.25m) in direction "AzimuthToCentreLine" and create point 1
            Move for bay width (typically 2.0m) in direction "AzimuthToCentreLine and create point 2
            Calculate Azimuth for line between vertex 0 and vertex 1
            Calc difference in Azimuths and decide < or > 180 (to indicate which side of kerb line to generate bay)

        For each vertex (starting at 1)
            Calculate Azimuth for current vertex and previous
            Calculate perpendicular to centre of road (using knowledge of which side of kerb line generated above)
            Move for bay width (typically 2.0m) along perpendicular and create point

        For last vertex
                Move for defined distance (typically 0.25m) along perpendicular and create last point

        for vertex 0


        for each vertex,
            calc angle at point
            if "first turn", i.e., initial azimuth +/- 90 (approx)
                get azimuth and distance from tracing line
                ignore vertices up to and include this one

            if "last turn", i.e., 90 turn
                get azimuth and distance from tracing line
                if distance is similar to first
                    ignore point and accept location on tracing line as end point
                    * check whether or not shape is likely to be rectangle and confirm number of points ...
            calc interior bisector at vertex
            generate point using interior bisector and distance from tracing line to "first turn"




        """

        line = generateGeometryUtils.getLineForAz(self.currFeature)

        TOMsMessageLog.logMessage("In reduceBayShape:  nr of pts = " + str(len(line)), level=Qgis.Info)

        if len(line) < 4:  # need at least four points
            return 0

        # Now have a valid set of points

        ptsList = []
        parallelPtsList = []
        nextAz = 0
        diffEchelonAz = 0

        # deal with start point
        startPointOnTraceLine = findNearestPointL(line[0], self.traceLineLayer, self.tolerance)
        #initialAzimuthToTraceLine = line[0].azimuth(startPointOnTraceLine)
        ptsList.append(startPointOnTraceLine)

        Turn = generateGeometryUtils.turnToCL(Az, generateGeometryUtils.checkDegrees(line[1].azimuth(line[2])))
        distanceFromTraceLine = startPointOnTraceLine.distance(self.currGeometry.vertexAt(1))

        for i in range(2, len(line) - 2, 1):

            TOMsMessageLog.logMessage("In reduceBayShape: i = " + str(i), level=Qgis.Info)
            Az = generateGeometryUtils.checkDegrees(line[i].azimuth(line[i + 1]))
            TOMsMessageLog.logMessage("In reduceBayShape: geometry: " + str(line[i].x()) + ":" + str(line[i].y()) + " " + str(line[i+1].x()) + ":" + str(line[i+1].y()) + " " + str(Az), level=Qgis.Info)
            # get angle at vertex

            angle = self.angleAtVertex( self.currGeometry.vertexAt(i), self.currGeometry.vertexAt(i-1),
                                         self.currGeometry.vertexAt(i+1))
            checkTurn = 90.0 - angle
            if abs(checkTurn) < 1.0:
                # this is a turn point and is not to be included in ptsList. Also consider this the end ...
                break
            else:

                newAz, distWidth = generateGeometryUtils.calcBisector(prevAz, Az, Turn, distanceFromTraceLine)

                # TOMsMessageLog.logMessage("In generate_display_geometry: newAz: " + str(newAz), level=Qgis.Info)

                cosa, cosb = generateGeometryUtils.cosdir_azim(newAz + diffEchelonAz)
                ptsList.append(
                    QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)))

            prevAz = Az

        # now add the last point

        lastPointOnTraceLine = findNearestPointL(line[i+1], self.traceLineLayer, self.tolerance)

        ptsList.append(lastPointOnTraceLine)

        newLine = QgsGeometry.fromPolylineXY(ptsList)

        # TOMsMessageLog.logMessage("In getDisplayGeometry:  newLine ********: " + newLine.asWkt(), level=Qgis.Info)

        return newLine

    def copyAttributesFromList(self):
        pass