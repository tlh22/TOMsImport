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

from abc import ABCMeta, abstractstaticmethod
import math

from .snapTraceUtilsMixin import snapTraceUtilsMixin
from TOMs.core.TOMsMessageLog import TOMsMessageLog
from TOMs.generateGeometryUtils import generateGeometryUtils

#class importLineString(QObject, snapTraceUtilsMixin):
class restrictionToImport(QObject, snapTraceUtilsMixin):

    def __init__(self, currFeature):
        super().__init__()

        self.currFeature = currFeature
        self.currGeometry = currFeature.geometry()
        self.tolerance = 0.5  # default

        QgsMessageLog.logMessage("In importLineString: {}".format(self.currFeature.attribute("GeometryID")), tag="TOMs panel")

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
        if self.currFeature.attribute("RestrictionTypeID") < 200:
            new_geom = self.reduceBayShape()
        else:
            new_geom = self.reduceLineShape()

        if new_geom:

            newRestriction = QgsFeature(self.currFeature.fields())

            currAttributes = self.currFeature.attributes()

            newRestriction.setGeometry(new_geom)
            newRestriction.setAttributes(currAttributes)
            #self.copyAttributesFromList(newRestriction, matchLists.baysMatchList)

            return newRestriction

        return None

    def reduceLineShape(self):
        # assume that points follow line - use snap/trace

        line = generateGeometryUtils.getLineForAz(self.currFeature)

        TOMsMessageLog.logMessage("In reduceLineShape:  orig nr of pts = " + str(len(line)), level=Qgis.Warning)

        if len(line) < 2:  # need at least two points
            return 0

        TOMsMessageLog.logMessage("In reduceLineShape:  starting nr of pts = " + str(len(line)), level=Qgis.Warning)
        # Now have a valid set of points

        ptsList = []
        parallelPtsList = []
        nextAz = 0
        diffEchelonAz = 0

        # deal with start point
        startPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[0], self.traceLineLayer, self.tolerance)

        if not startPointOnTraceLine:
            TOMsMessageLog.logMessage("In reduceLineShape:  Start point not within tolerance. Returning original geometry", level=Qgis.Warning)
            return self.currGeometry

        ptsList.append(startPointOnTraceLine.asPoint())

        startAzimuth = generateGeometryUtils.checkDegrees(startPointOnTraceLine.asPoint().azimuth(line[0]))

        TOMsMessageLog.logMessage("In reduceLineShape: start point: {}".format(
                                  startPointOnTraceLine.asPoint().asWkt()),
                                  level=Qgis.Warning)

        initialAzimuth = generateGeometryUtils.checkDegrees(line[0].azimuth(line[1]))

        Turn = generateGeometryUtils.turnToCL(startAzimuth, initialAzimuth)
        #Turn = 0.0
        distanceFromTraceLine = startPointOnTraceLine.distance(QgsGeometry.fromPointXY(QgsPointXY(self.currGeometry.vertexAt(0))))
        # find distance from line to "second" point (assuming it is the turn point)

        traceStartVertex = 1
        for i in range(traceStartVertex, len(line)-1, 1):

            TOMsMessageLog.logMessage("In reduceLineShape: i = " + str(i), level=Qgis.Warning)
            Az = generateGeometryUtils.checkDegrees(line[i].azimuth(line[i + 1]))

            if i == traceStartVertex:
                prevAz = initialAzimuth
                #Turn = generateGeometryUtils.turnToCL(prevAz, Az)

            TOMsMessageLog.logMessage("In reduceLineShape: geometry: " + str(line[i].x()) + ":" + str(line[i].y()) + " " + str(line[i+1].x()) + ":" + str(line[i+1].y()) + " " + str(Az), level=Qgis.Warning)
            # get angle at vertex

            #angle = self.angleAtVertex( self.currGeometry.vertexAt(i), self.currGeometry.vertexAt(i-1),
            #                             self.currGeometry.vertexAt(i+1))
            #checkTurn = 90.0 - angle

            newAz, distWidth = generateGeometryUtils.calcBisector(prevAz, Az, Turn, distanceFromTraceLine)

            TOMsMessageLog.logMessage("In reduceLineShape: newAz: " + str(newAz), level=Qgis.Warning)

            cosa, cosb = generateGeometryUtils.cosdir_azim(newAz + diffEchelonAz)
            ptsList.append(
                QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)))
            TOMsMessageLog.logMessage("In reduceLineShape: point: {}".format(QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)).asWkt()),
                                      level=Qgis.Warning)

            prevAz = Az

        # now add the last point

        #lastPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[i+1], self.traceLineLayer, self.tolerance)  # TODO: need this logic
        lastPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[len(line)-1], self.traceLineLayer, self.tolerance)  # issues for multi-line features
        if not lastPointOnTraceLine:
            TOMsMessageLog.logMessage("In reduceLineShape:  Last point not within tolerance.", level=Qgis.Warning)
            lastPointOnTraceLine = QgsGeometry.fromPointXY(line[len(line)-1])

        ptsList.append(lastPointOnTraceLine.asPoint())

        ptNr = 0
        for thisPt in ptsList:
            TOMsMessageLog.logMessage("In reduceLineShape: ptsList {}: {}".format(ptNr, thisPt.asWkt()), level=Qgis.Warning)
            ptNr = ptNr + 1

        newLine = QgsGeometry.fromPolylineXY(ptsList)

        TOMsMessageLog.logMessage("In reduceLineShape:  newLine ********: " + newLine.asWkt(), level=Qgis.Warning)

        return newLine


    def reduceBayShape(self):

        # check start/end points are within tolerance of the tracing line (typically kerb)

        # check if start/end points are the same. Likely to be a rectangle ...  # TODO

        # check whether or not echelon ... (Seems to be OK without this check)

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

        origLine = generateGeometryUtils.getLineForAz(self.currFeature)

        TOMsMessageLog.logMessage("In reduceBayShape:  nr of pts = " + str(len(origLine)), level=Qgis.Warning)

        if len(origLine) < 4:  # need at least four points
            TOMsMessageLog.logMessage(
                "In reduceBayShape:  Less than four points. Returning original geometry", level=Qgis.Warning)
            return self.currGeometry

        # Now have a valid set of points

        ptsList = []
        parallelPtsList = []
        nextAz = 0
        diffEchelonAz = 0

        # "normalise" bay shape

        lineA = self.removeKickBackVertices(origLine)
        line = self.prepareSelfClosingBays(lineA, self.traceLineLayer)

        # deal with situations where the start point and end point are the same (or close)
        TOMsMessageLog.logMessage("In reduceLineShape:  starting nr of pts = " + str(len(line)), level=Qgis.Warning)

        # Now "reduce"
        traceStartVertex = 0
        # deal with start point
        startPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[traceStartVertex], self.traceLineLayer, self.tolerance)

        if not startPointOnTraceLine:
            TOMsMessageLog.logMessage(
                "In reduceBayShape:  Start point not within tolerance. Returning original geometry",
                level=Qgis.Warning)
            return self.currGeometry

        ptsList.append(startPointOnTraceLine.asPoint())
        TOMsMessageLog.logMessage("In reduceBayShape: start point: {}".format(
                                  startPointOnTraceLine.asPoint().asWkt()),
                                  level=Qgis.Warning)

        Az = generateGeometryUtils.checkDegrees(line[traceStartVertex].azimuth(line[traceStartVertex+1]))
        initialAzimuth = Az
        TOMsMessageLog.logMessage("In reduceBayShape: initialAzimuth: " + str(initialAzimuth), level=Qgis.Warning)
        #Turn = generateGeometryUtils.turnToCL(Az, generateGeometryUtils.checkDegrees(line[traceStartVertex+1].azimuth(line[traceStartVertex+2])))
        distanceFromTraceLine = startPointOnTraceLine.distance(QgsGeometry.fromPointXY(QgsPointXY(line[traceStartVertex+1])))
        # find distance from line to "second" point (assuming it is the turn point)

        traceStartVertex = traceStartVertex + 1
        initialLastVertex = len(line)-1
        traceLastVertex = initialLastVertex

        for i in range(traceStartVertex, initialLastVertex, 1):


            Az = generateGeometryUtils.checkDegrees(line[i].azimuth(line[i + 1]))
            angle = self.angleAtVertex( line[i], line[i-1], line[i+1])
            checkTurn = 90.0 - angle
            TOMsMessageLog.logMessage("In reduceBayShape: i = {}; angle: {}; checkTurn: {}".format(i, angle, checkTurn), level=Qgis.Warning)

            if i == traceStartVertex:
                # assume that first point is already in ptsList
                prevAz = initialAzimuth
                Turn = generateGeometryUtils.turnToCL(prevAz, Az)
                TOMsMessageLog.logMessage("In reduceBayShape: turn: {}; dist: {}".format(Turn, distanceFromTraceLine),
                                          level=Qgis.Warning)

            elif abs(checkTurn) < 1.0:   # TODO: This could be a line at a right angle corner. Need to check ??
                # this is a turn point and is not to be included in ptsList. Also consider this the end ...
                TOMsMessageLog.logMessage("In reduceBayShape: turn point. Exiting reduce loop at {}".format(i) , level=Qgis.Warning)
                traceLastVertex = i + 1  # ignore current vertex and use next vertex as last
                break

            else:

                TOMsMessageLog.logMessage("In reduceBayShape: geometry: pt1 {}:{}; pt2 {}:{}; Az: {}".format(line[i].x(), line[i].y(), line[i+1].x(), line[i+1].y(), Az), level=Qgis.Warning)
                # get angle at vertex

                newAz, distWidth = generateGeometryUtils.calcBisector(prevAz, Az, Turn, distanceFromTraceLine)

                TOMsMessageLog.logMessage("In reduceBayShape: newAz: " + str(newAz), level=Qgis.Warning)

                cosa, cosb = generateGeometryUtils.cosdir_azim(newAz + diffEchelonAz)
                ptsList.append(
                    QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)))
                TOMsMessageLog.logMessage("In reduceBayShape: point: {}".format(QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)).asWkt()),
                                          level=Qgis.Warning)

            prevAz = Az
            traceLastVertex = i + 1

        # now add the last point

        lastPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[traceLastVertex], self.traceLineLayer, self.tolerance)  # issues for multi-line features

        if not lastPointOnTraceLine:
            TOMsMessageLog.logMessage("In reduceBayShape:  Last point not within tolerance.", level=Qgis.Warning)
            lastPointOnTraceLine = QgsGeometry.fromPointXY(line[traceLastVertex])

        ptsList.append(lastPointOnTraceLine.asPoint())

        ptNr = 0
        for thisPt in ptsList:
            TOMsMessageLog.logMessage("In reduceBayShape: ptsList {}: {}".format(ptNr, thisPt.asWkt()), level=Qgis.Warning)
            ptNr = ptNr + 1

        newLine = QgsGeometry.fromPolylineXY(ptsList)

        TOMsMessageLog.logMessage("In reduceBayShape:  newLine ********: " + newLine.asWkt(), level=Qgis.Warning)

        return newLine

    def isBetween(self, pointA, pointB, pointC):
        # https://stackoverflow.com/questions/328107/how-can-you-determine-a-point-is-between-two-other-points-on-a-line-segment
        # determines whether C lies on line A-B

        delta = 0.25

        # check to see whether or not point C lies within a buffer for A-B
        lineGeom = QgsGeometry.fromPolylineXY([pointA, pointB])
        TOMsMessageLog.logMessage("In isBetween:  lineGeom ********: " + lineGeom.asWkt(), level=Qgis.Warning)
        buff = lineGeom.buffer(delta, 0, QgsGeometry.CapFlat, QgsGeometry.JoinStyleBevel, 1.0)
        TOMsMessageLog.logMessage("In isBetween:  buff ********: " + buff.asWkt(), level=Qgis.Warning)

        if QgsGeometry.fromPointXY(pointC).within(buff):
            # candidate. Now check simple distances
            TOMsMessageLog.logMessage("In isBetween:  point is within buffer ...", level=Qgis.Warning)
            distAB = self.distance(pointA, pointB)
            distAC = self.distance(pointA, pointC)
            distBC = self.distance(pointB, pointC)

            TOMsMessageLog.logMessage("In isBetween:  distances: {}; {}; {}".format(distAB, distAC, distBC), level=Qgis.Warning)

            if abs(distAB - distAC) > (distBC - delta):
                return True

        return False

    def distance(self, pointA, pointB):
        return math.sqrt((pointA.x() - pointB.x()) ** 2 + (pointA.y() - pointB.y()) ** 2)

    def removeKickBackVertices(self, origLine):

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

        traceStartVertex = 0
        while True:
            # check whether or not points 0-2 are co-linear
            if not self.isBetween(origLine[traceStartVertex + 1], origLine[traceStartVertex + 2], origLine[traceStartVertex]):
                break
            traceStartVertex = traceStartVertex + 1

        traceLastVertex = len(origLine) - 1
        while True:
            # check whether or not points are co-linear
            if not self.isBetween(origLine[traceLastVertex-1], origLine[traceLastVertex-2], origLine[traceLastVertex]):
                break
            traceLastVertex = traceLastVertex - 1

        TOMsMessageLog.logMessage("In removeKickBackVertices:  first: {}; last {}".format(traceStartVertex, traceLastVertex),
                                  level=Qgis.Warning)
        # now remove vertices that are not required
        for i in range(traceStartVertex, traceLastVertex+1, 1):
            newLine.append(origLine[i])

        return newLine

    def prepareSelfClosingBays(self, line, traceLayer):
        """ identify bays that loop
           2 ---------------------3
            |                   |
            |                   |
            |                   | 4
            -------------------
            1                    0

        """
        tolerance = 0.5
        intesectingPts = []
        newLine = []
        geomShapeID = 0

        # check proximity of end points

        if QgsGeometry.fromPointXY(line[0]).distance(QgsGeometry.fromPointXY(line[len(line)-1])) < tolerance:
            # we have a loop - find the intersection points on the trace line
            # get a bounding box of the line

            lineGeom = QgsGeometry.fromPolylineXY(line)
            bbox = lineGeom.boundingBox()

            request = QgsFeatureRequest()
            request.setFilterRect(bbox)
            request.setFlags(QgsFeatureRequest.ExactIntersect)

            shortestDistance = float("inf")
            # nearestPoint = QgsFeature()

            # Loop through all features in the layer to find the closest feature
            for f in traceLayer.getFeatures(request):
                TOMsMessageLog.logMessage("In prepareSelfClosingBays: {}".format(f.id()), level=Qgis.Info)

                # now check to see whether there is an intersection with this feature on the traceLayer and the lineGeom
                intesectingPtsGeom = f.geometry().intersection(lineGeom)

                if intesectingPtsGeom:
                    # add them to a list of pts
                    for part in intesectingPtsGeom.parts():
                        intesectingPts.append(part)

            if len(intesectingPts) == 2:
                # if 2, generate list of points between the two and return.
                # work out distance along line for each intersection point

                startDistance = float("inf")
                endDistance = 0.0
                for pt in intesectingPts:
                    vertexCoord, vertex, prevVertex, nextVertex, distSquared = \
                        lineGeom.closestVertex(QgsPointXY(pt))

                    distance = math.sqrt(distSquared)
                    if distance < startDistance:
                        startPt = pt
                        startDistance = distance
                        startVertex = vertex
                        if lineGeom.distanceToVertex(startVertex) < startDistance:
                            startVertex = nextVertex

                    if distance > endDistance:
                        endPt = pt
                        endDistance = distance
                        endVertex = vertex
                        if lineGeom.distanceToVertex(endVertex) > endDistance:
                            endVertex = prevVertex

                # move along line ...
                if not QgsGeometry.fromPointXY(QgsPointXY(startPt)).equals(QgsGeometry.fromPointXY(QgsPointXY(lineGeom.vertexAt(startVertex)))):
                    # add start pt
                    newLine.append(QgsPointXY(startPt))

                for i in range(startVertex, endVertex + 1, 1):
                    newLine.append(line[i])

                if not QgsGeometry.fromPointXY(QgsPointXY(endPt)).equals(QgsGeometry.fromPointXY(QgsPointXY(lineGeom.vertexAt(endVertex)))):
                    # add start pt
                    newLine.append(QgsPointXY(endPt))

                geomShapeID = 2  # half-on/half-off bay

            elif len(intesectingPts) == 0:
                # check whether or not shape is inside or outside the road casement.

                # move around shape and include any points that are within tolerance of the traceLayer

                newLine = line  # return the original geometry

                #geomShapeID = 3  # on pavement bay

            else:
                newLine = line  # return the original geometry

        else:
            newLine = line  # return the original geometry

        return newLine, geomShapeID



