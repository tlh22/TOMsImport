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
    Qgis,
    QgsMessageLog, QgsFeature, QgsGeometry,
    QgsFeatureRequest,
    QgsRectangle, QgsPointXY, QgsWkbTypes
)

import math
from TOMs.generateGeometryUtils import generateGeometryUtils
from TOMs.core.TOMsMessageLog import TOMsMessageLog

class snapTraceUtilsMixin():

    def __init__(self):
        pass

    def findNearestPointL(self, searchPt, lineLayer, tolerance):
        # given a point, find the nearest point (within the tolerance) within the line layer
        # returns QgsPoint
        QgsMessageLog.logMessage("In findNearestPointL. Checking lineLayer: " + lineLayer.name() + "; " + searchPt.asWkt(), tag="TOMs panel")
        searchRect = QgsRectangle(searchPt.x() - tolerance,
                                  searchPt.y() - tolerance,
                                  searchPt.x() + tolerance,
                                  searchPt.y() + tolerance)

        request = QgsFeatureRequest()
        request.setFilterRect(searchRect)
        request.setFlags(QgsFeatureRequest.ExactIntersect)

        shortestDistance = float("inf")
        #nearestPoint = QgsFeature()

        # Loop through all features in the layer to find the closest feature
        for f in lineLayer.getFeatures(request):
            # Add any features that are found should be added to a list

            closestPtOnFeature = f.geometry().nearestPoint(QgsGeometry.fromPointXY(searchPt))
            dist = f.geometry().distance(QgsGeometry.fromPointXY(searchPt))
            if dist < shortestDistance:
                shortestDistance = dist
                closestPoint = closestPtOnFeature

        QgsMessageLog.logMessage("In findNearestPointL: shortestDistance: " + str(shortestDistance), tag="TOMs panel")

        del request
        del searchRect

        if shortestDistance < float("inf"):
            #nearestPoint = QgsFeature()
            # add the geometry to the feature,
            #nearestPoint.setGeometry(QgsGeometry(closestPtOnFeature))
            #QgsMessageLog.logMessage("findNearestPointL: nearestPoint geom type: " + str(nearestPoint.wkbType()), tag="TOMs panel")
            return closestPoint   # returns a geometry
        else:
            return None

    def nearbyLineFeature(self, currFeatureGeom, searchLineLayer, tolerance):

        QgsMessageLog.logMessage("In nearbyLineFeature - lineLayer", tag="TOMs panel")

        nearestLine = None

        for currVertexNr, currVertexPt in enumerate(currFeatureGeom.asPolyline()):

            nearestLine = self.findNearestLine(currVertexPt, searchLineLayer, tolerance)
            if nearestLine:
                break

        return nearestLine

    def findNearestLine(self, searchPt, lineLayer, tolerance):
        # given a point, find the nearest point (within the tolerance) within the line layer
        # returns QgsPoint
        QgsMessageLog.logMessage("In findNearestLine - lineLayer", tag="TOMs panel")
        searchRect = QgsRectangle(searchPt.x() - tolerance,
                                  searchPt.y() - tolerance,
                                  searchPt.x() + tolerance,
                                  searchPt.y() + tolerance)

        request = QgsFeatureRequest()
        request.setFilterRect(searchRect)
        request.setFlags(QgsFeatureRequest.ExactIntersect)

        shortestDistance = float("inf")

        # Loop through all features in the layer to find the closest feature
        for f in lineLayer.getFeatures(request):
            # Add any features that are found should be added to a list

            # closestPtOnFeature = f.geometry().nearestPoint(QgsGeometry.fromPoint(searchPt))
            dist = f.geometry().distance(QgsGeometry.fromPointXY(searchPt))
            if dist < shortestDistance:
                shortestDistance = dist
                closestLine = f

        QgsMessageLog.logMessage("In findNearestLine: shortestDistance: " + str(shortestDistance), tag="TOMs panel")

        del request
        del searchRect

        if shortestDistance < float("inf"):

            """QgsMessageLog.logMessage("In findNearestLine: closestLine {}".format(closestLine.exportToWkt()),
                                     tag="TOMs panel")"""

            return closestLine   # returns a geometry
        else:
            return None

    def azimuth(self, point1, point2):
        '''azimuth between 2 shapely points (interval 0 - 360)'''
        angle = math.atan2(point2.x() - point1.x(), point2.y() - point1.y())
        return math.degrees(angle)if angle>0 else math.degrees(angle) + 360

    def angleAtVertex(self, pt, ptBefore, ptAfter):
        angle = abs(self.azimuth(pt, ptAfter) - self.azimuth(pt, ptBefore))

        if angle > 180.0:
            angle = 360.0 - angle

        return angle

    def isBetween(self, pointA, pointB, pointC, delta=None):
        # https://stackoverflow.com/questions/328107/how-can-you-determine-a-point-is-between-two-other-points-on-a-line-segment
        # determines whether C lies on line A-B

        if delta is None:
            delta = 0.25

        # check to see whether or not point C lies within a buffer for A-B
        lineGeom_AB = QgsGeometry.fromPolylineXY([pointA, pointB])
        TOMsMessageLog.logMessage("In isBetween:  lineGeom ********: " + lineGeom_AB.asWkt(), level=Qgis.Info)
        buff = lineGeom_AB  .buffer(delta, 0, QgsGeometry.CapFlat, QgsGeometry.JoinStyleBevel, 1.0)
        #TOMsMessageLog.logMessage("In isBetween:  buff ********: " + buff.asWkt(), level=Qgis.Info)

        if QgsGeometry.fromPointXY(pointC).intersects(buff):
            # candidate. Now check simple distances
            TOMsMessageLog.logMessage("In isBetween:  point is within buffer ...", level=Qgis.Info)
            lineGeom_AC = QgsGeometry.fromPolylineXY([pointA, pointC])
            lineGeom_BC = QgsGeometry.fromPolylineXY([pointB, pointC])
            distAB = lineGeom_AB.length()
            distAC = lineGeom_AC.length()
            distBC = lineGeom_BC.length()

            TOMsMessageLog.logMessage("In isBetween:  distances: {}; {}; {}".format(distAB, distAC, distBC), level=Qgis.Info)

            if abs(distAB - distAC) > (distBC - delta):
                return True

        return False

    def distance(self, pointA, pointB):
        return math.sqrt((pointA.x() - pointB.x()) ** 2 + (pointA.y() - pointB.y()) ** 2)

    def removeKickBackVertices(self, origLine, tolerance=None):

        """ Need to check for "kick-back" type structure, i.e., where the points are like this:

                -------------------------------
                | 2                             | 3
                |
                | 0
                |
                | 1

                -----------------------------------

        """
        newLine = []

        # check in forward direction
        traceStartVertex = 0
        while True:
            if traceStartVertex+2 > len(origLine) - 1:
                break
            # check whether or not points 0-2 are co-linear
            if not self.isBetween(origLine[traceStartVertex + 1], origLine[traceStartVertex + 2], origLine[traceStartVertex], tolerance):
                break
            traceStartVertex = traceStartVertex + 1

        # check in reverse direction
        traceLastVertex = len(origLine) - 1
        while True:
            if traceLastVertex-2 < 0:
                break
            # check whether or not points are co-linear
            if not self.isBetween(origLine[traceLastVertex-1], origLine[traceLastVertex-2], origLine[traceLastVertex], tolerance):
                break
            traceLastVertex = traceLastVertex - 1

        # now remove vertices that are not required
        for i in range(traceStartVertex, traceLastVertex+1, 1):  # remember stop number is not included in loop
            newLine.append(origLine[i])

        TOMsMessageLog.logMessage("In removeKickBackVertices:  first: {}; last {}".format(traceStartVertex, traceLastVertex),
                                  level=Qgis.Info)

        # also check situation where the last point is after end of loop, i.e., sits between points 0 and 1
        """
        # this approach removes any vertices that are between others - perhaps a bit violent, but ...
        verticesToRemove = set()

        for currVertex in range(0, len(origLine) - 1, 1):

            i = 0
            while True:
                startVertex = i
                endVertex = i + 1

                if startVertex == len(origLine)-1:
                    break

                lineSegment = QgsGeometry.fromPolylineXY([origLine[startVertex], origLine[endVertex]])
                TOMsMessageLog.logMessage(
                    "In removeKickBackVertices: currVertex: {}; i: {}; start: {}; end: {}".format(currVertex, i, origLine[startVertex].asWkt(),
                                                                              origLine[endVertex].asWkt()),
                    level=Qgis.Info)

                if currVertex == startVertex or currVertex == endVertex:
                    if lineSegment.within(QgsGeometry.fromPointXY(origLine[currVertex]).buffer(0.1, 5)):
                        verticesToRemove.add(currVertex)
                        TOMsMessageLog.logMessage("In removeKickBackVertices: removing vertex {}".format(currVertex), level=Qgis.Info)
                else:
                    if lineSegment.intersects(QgsGeometry.fromPointXY(origLine[currVertex]).buffer(0.1, 5)):
                        verticesToRemove.add(currVertex)
                        TOMsMessageLog.logMessage("In removeKickBackVertices 2: removing vertex {}".format(currVertex), level=Qgis.Info)

                i = i + 1

        newLine = origLine

        for vertex in verticesToRemove:
            del newLine[vertex]
        """
        TOMsMessageLog.logMessage("In removeKickBackVertices: len newLine {}".format(len(newLine)),
                                  level=Qgis.Info)

        return newLine

