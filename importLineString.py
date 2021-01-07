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
        self.currGeomShapeID = self.currFeature.attribute("GeomShapeID")

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

        geomShapeID = 10 # line
        # check feature type - based on "RestrictionTypeID"
        if self.currFeature.attribute("RestrictionTypeID") < 200:
            new_geom, geomShapeID = self.reduceBayShape()
        else:
            new_geom = self.reduceLineShape()

        if new_geom:

            newRestriction = QgsFeature(self.currFeature.fields())

            currAttributes = self.currFeature.attributes()

            newRestriction.setGeometry(new_geom)
            newRestriction.setAttributes(currAttributes)
            newRestriction.setAttribute("GeomShapeID", geomShapeID)
            #self.copyAttributesFromList(newRestriction, matchLists.baysMatchList)

            return newRestriction

        return None

    def reduceLineShape(self):
        # assume that points follow line - use snap/trace

        line = generateGeometryUtils.getLineForAz(self.currFeature)

        TOMsMessageLog.logMessage("In reduceLineShape:  orig nr of pts = " + str(len(line)), level=Qgis.Info)

        if len(line) < 2:  # need at least two points
            return 0

        TOMsMessageLog.logMessage("In reduceLineShape:  starting nr of pts = " + str(len(line)), level=Qgis.Info)
        # Now have a valid set of points

        ptsList = []
        parallelPtsList = []
        nextAz = 0
        diffEchelonAz = 0

        # deal with start point
        startPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[0], self.traceLineLayer, self.tolerance)

        if not startPointOnTraceLine:
            TOMsMessageLog.logMessage("In reduceLineShape:  Start point not within tolerance. Returning original geometry", level=Qgis.Info)
            return self.currGeometry

        ptsList.append(startPointOnTraceLine.asPoint())

        startAzimuth = generateGeometryUtils.checkDegrees(startPointOnTraceLine.asPoint().azimuth(line[0]))

        TOMsMessageLog.logMessage("In reduceLineShape: start point: {}".format(
                                  startPointOnTraceLine.asPoint().asWkt()),
                                  level=Qgis.Info)

        initialAzimuth = generateGeometryUtils.checkDegrees(line[0].azimuth(line[1]))

        Turn = generateGeometryUtils.turnToCL(startAzimuth, initialAzimuth)
        #Turn = 0.0
        distanceFromTraceLine = startPointOnTraceLine.distance(QgsGeometry.fromPointXY(QgsPointXY(self.currGeometry.vertexAt(0))))
        # find distance from line to "second" point (assuming it is the turn point)

        traceStartVertex = 1
        for i in range(traceStartVertex, len(line)-1, 1):

            TOMsMessageLog.logMessage("In reduceLineShape: i = " + str(i), level=Qgis.Info)
            Az = generateGeometryUtils.checkDegrees(line[i].azimuth(line[i + 1]))

            if i == traceStartVertex:
                prevAz = initialAzimuth
                #Turn = generateGeometryUtils.turnToCL(prevAz, Az)

            TOMsMessageLog.logMessage("In reduceLineShape: geometry: " + str(line[i].x()) + ":" + str(line[i].y()) + " " + str(line[i+1].x()) + ":" + str(line[i+1].y()) + " " + str(Az), level=Qgis.Info)
            # get angle at vertex

            #angle = self.angleAtVertex( self.currGeometry.vertexAt(i), self.currGeometry.vertexAt(i-1),
            #                             self.currGeometry.vertexAt(i+1))
            #checkTurn = 90.0 - angle

            newAz, distWidth = generateGeometryUtils.calcBisector(prevAz, Az, Turn, distanceFromTraceLine)

            TOMsMessageLog.logMessage("In reduceLineShape: newAz: " + str(newAz), level=Qgis.Info)

            cosa, cosb = generateGeometryUtils.cosdir_azim(newAz + diffEchelonAz)
            ptsList.append(
                QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)))
            TOMsMessageLog.logMessage("In reduceLineShape: point: {}".format(QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)).asWkt()),
                                      level=Qgis.Info)

            prevAz = Az

        # now add the last point

        #lastPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[i+1], self.traceLineLayer, self.tolerance)  # TODO: need this logic
        lastPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[len(line)-1], self.traceLineLayer, self.tolerance)  # issues for multi-line features
        if not lastPointOnTraceLine:
            TOMsMessageLog.logMessage("In reduceLineShape:  Last point not within tolerance.", level=Qgis.Info)
            lastPointOnTraceLine = QgsGeometry.fromPointXY(line[len(line)-1])

        ptsList.append(lastPointOnTraceLine.asPoint())

        ptNr = 0
        for thisPt in ptsList:
            TOMsMessageLog.logMessage("In reduceLineShape: ptsList {}: {}".format(ptNr, thisPt.asWkt()), level=Qgis.Info)
            ptNr = ptNr + 1

        newLine = QgsGeometry.fromPolylineXY(ptsList)

        TOMsMessageLog.logMessage("In reduceLineShape:  newLine ********: " + newLine.asWkt(), level=Qgis.Info)

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

        TOMsMessageLog.logMessage("In reduceBayShape:  nr of pts = " + str(len(origLine)), level=Qgis.Info)

        if len(origLine) < 4:  # need at least four points
            TOMsMessageLog.logMessage(
                "In reduceBayShape:  Less than four points. Returning original geometry", level=Qgis.Warning)
            return self.currGeometry, self.currGeomShapeID

        # Now have a valid set of points

        ptsList = []
        parallelPtsList = []
        nextAz = 0
        diffEchelonAz = 0

        # "normalise" bay shape

        lineA = self.removeKickBackVertices(origLine)
        line, geomShapeID = self.prepareSelfClosingBays(lineA, self.traceLineLayer)

        if len(line) < 4:  # need at least four points
            TOMsMessageLog.logMessage(
                "In reduceBayShape 2:  Less than four points. Returning original geometry", level=Qgis.Warning)
            return self.currGeometry, self.currGeomShapeID

        # deal with situations where the start point and end point are the same (or close)
        TOMsMessageLog.logMessage("In reduceLineShape:  starting nr of pts = " + str(len(line)), level=Qgis.Warning)

        # Now "reduce"
        traceStartVertex = 0
        # deal with start point
        startPointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(line[traceStartVertex], self.traceLineLayer, self.tolerance)

        if not startPointOnTraceLine:

            newLine = self.getVerticesWithinTolerance(line, self.traceLineLayer, self.tolerance)

            TOMsMessageLog.logMessage(
                "In reduceBayShape:  Start point not within tolerance. Returning best possible geometry",
                level=Qgis.Warning)

            if newLine:
                return newLine, self.currGeomShapeID
            return self.currGeometry, self.currGeomShapeID

        ptsList.append(startPointOnTraceLine.asPoint())
        TOMsMessageLog.logMessage("In reduceBayShape: start point: {}".format(
                                  startPointOnTraceLine.asPoint().asWkt()),
                                  level=Qgis.Info)

        Az = generateGeometryUtils.checkDegrees(line[traceStartVertex].azimuth(line[traceStartVertex+1]))
        initialAzimuth = Az
        TOMsMessageLog.logMessage("In reduceBayShape: initialAzimuth: " + str(initialAzimuth), level=Qgis.Info)
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
            TOMsMessageLog.logMessage("In reduceBayShape: i = {}; angle: {}; checkTurn: {}".format(i, angle, checkTurn), level=Qgis.Info)

            if i == traceStartVertex:
                # assume that first point is already in ptsList
                prevAz = initialAzimuth
                Turn = generateGeometryUtils.turnToCL(prevAz, Az)
                TOMsMessageLog.logMessage("In reduceBayShape: turn: {}; dist: {}".format(Turn, distanceFromTraceLine),
                                          level=Qgis.Info)

            elif abs(checkTurn) < 1.0:   # TODO: This could be a line at a right angle corner. Need to check ??
                # this is a turn point and is not to be included in ptsList. Also consider this the end ...
                TOMsMessageLog.logMessage("In reduceBayShape: turn point. Exiting reduce loop at {}".format(i) , level=Qgis.Info)
                traceLastVertex = i + 1  # ignore current vertex and use next vertex as last
                break

            else:

                TOMsMessageLog.logMessage("In reduceBayShape: geometry: pt1 {}:{}; pt2 {}:{}; Az: {}".format(line[i].x(), line[i].y(), line[i+1].x(), line[i+1].y(), Az), level=Qgis.Info)
                # get angle at vertex

                newAz, distWidth = generateGeometryUtils.calcBisector(prevAz, Az, Turn, distanceFromTraceLine)

                TOMsMessageLog.logMessage("In reduceBayShape: newAz: " + str(newAz), level=Qgis.Info)

                cosa, cosb = generateGeometryUtils.cosdir_azim(newAz + diffEchelonAz)
                ptsList.append(
                    QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)))
                TOMsMessageLog.logMessage("In reduceBayShape: point: {}".format(QgsPointXY(line[i].x() + (float(distWidth) * cosa), line[i].y() + (float(distWidth) * cosb)).asWkt()),
                                          level=Qgis.Info)

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
            TOMsMessageLog.logMessage("In reduceBayShape: ptsList {}: {}".format(ptNr, thisPt.asWkt()), level=Qgis.Info)
            ptNr = ptNr + 1

        newLine = QgsGeometry.fromPolylineXY(ptsList)

        TOMsMessageLog.logMessage("In reduceBayShape:  newLine ********: " + newLine.asWkt(), level=Qgis.Info)

        return newLine, geomShapeID

    def isBetween(self, pointA, pointB, pointC):
        # https://stackoverflow.com/questions/328107/how-can-you-determine-a-point-is-between-two-other-points-on-a-line-segment
        # determines whether C lies on line A-B

        delta = 0.25

        # check to see whether or not point C lies within a buffer for A-B
        lineGeom = QgsGeometry.fromPolylineXY([pointA, pointB])
        TOMsMessageLog.logMessage("In isBetween:  lineGeom ********: " + lineGeom.asWkt(), level=Qgis.Info)
        buff = lineGeom.buffer(delta, 0, QgsGeometry.CapFlat, QgsGeometry.JoinStyleBevel, 1.0)
        #TOMsMessageLog.logMessage("In isBetween:  buff ********: " + buff.asWkt(), level=Qgis.Info)

        if QgsGeometry.fromPointXY(pointC).intersects(buff):
            # candidate. Now check simple distances
            TOMsMessageLog.logMessage("In isBetween:  point is within buffer ...", level=Qgis.Info)
            distAB = self.distance(pointA, pointB)
            distAC = self.distance(pointA, pointC)
            distBC = self.distance(pointB, pointC)

            TOMsMessageLog.logMessage("In isBetween:  distances: {}; {}; {}".format(distAB, distAC, distBC), level=Qgis.Info)

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

        # now remove vertices that are not required
        for i in range(traceStartVertex, traceLastVertex+1, 1):
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

    def prepareSelfClosingBays(self, inputLine, traceLayer):
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
        geomShapeID = 1

        lineA = self.removeDanglingEndFromLoop(inputLine)

        # check proximity of end points
        if not QgsGeometry.fromPointXY(lineA[0]).distance(QgsGeometry.fromPointXY(lineA[len(lineA)-1])) < tolerance:
            return inputLine, geomShapeID

        TOMsMessageLog.logMessage("In prepareSelfClosingBays: we have a loop ... ", level=Qgis.Warning)

        line = lineA
        # we have a loop - find the intersection points on the trace line
        # get a bounding box of the line

        lineGeom = QgsGeometry.fromPolylineXY(line)
        bbox = lineGeom.boundingBox()

        request = QgsFeatureRequest()
        request.setFilterRect(bbox)
        request.setFlags(QgsFeatureRequest.ExactIntersect)

        # Loop through all features in the layer to find the intersecting feature(s)
        for f in traceLayer.getFeatures(request):
            TOMsMessageLog.logMessage("In prepareSelfClosingBays: traceLayer id: {}".format(f.id()), level=Qgis.Info)

            # now check to see whether there is an intersection with this feature on the traceLayer and the lineGeom
            intesectingPtsGeom = f.geometry().intersection(lineGeom)

            if intesectingPtsGeom:
                # add them to a list of pts
                TOMsMessageLog.logMessage(
                "In prepareSelfClosingBays: intersecting geom: {}".format(
                    intesectingPtsGeom.asWkt()), level = Qgis.Info)
                for part in intesectingPtsGeom.parts():
                    TOMsMessageLog.logMessage(
                        "In prepareSelfClosingBays: intersecting part: {}".format(
                            part.asWkt()), level=Qgis.Info)
                    intesectingPts.append(QgsPointXY(part))

        TOMsMessageLog.logMessage("In prepareSelfClosingBays: nr of pts intersecting tracelayer: {}".format(len(intesectingPts)), level=Qgis.Info)

        if len(intesectingPts) == 2:
            # if 2, generate list of points between the two and return.
            # work out distance along line for each intersection point

            startDistance = float("inf")
            endDistance = 0.0

            for ptXY in intesectingPts:
                # ptXY = QgsPointXY(pt)
                TOMsMessageLog.logMessage(
                    "In prepareSelfClosingBays: considering intersection point: {}".format(ptXY.asWkt()),
                    level=Qgis.Info)

                vertexCoord, vertex, prevVertex, nextVertex, distSquared = lineGeom.closestVertex(ptXY)

                TOMsMessageLog.logMessage(
                    "In prepareSelfClosingBays: considering closestVertex: {}; prevVertex: {}; nextVertex: {}".format(vertex, prevVertex, nextVertex),
                    level=Qgis.Info)

                vertex, prevVertex, nextVertex = self.ensureVerticesNumberFromLineStart(len(line)-1, vertex, prevVertex, nextVertex)

                distToVertex = lineGeom.distanceToVertex(vertex)
                distToPt, prevVertex = self.getDistanceToPoint(ptXY, line)
                #dist = math.sqrt(distSquared)

                TOMsMessageLog.logMessage(
                    "In prepareSelfClosingBays: considering closestVertex: {}; distToVertex: {}; distToPt: {}".format(vertex, distToVertex, distToPt),
                    level=Qgis.Info)

                if distToPt < startDistance:
                    startDistance = distToPt
                    startPt = ptXY
                    if distToVertex <= distToPt:
                        startVertex = nextVertex
                    else:
                        startVertex = vertex

                    TOMsMessageLog.logMessage("In prepareSelfClosingBays: new startVertex: {}".format(startVertex), level=Qgis.Info)

                if vertex == 0:
                    distToVertex = lineGeom.length()
                    TOMsMessageLog.logMessage("In prepareSelfClosingBays: with vertex = 0, changing distToVertex to {}".format(distToVertex),
                                              level=Qgis.Info)
                if distToPt > endDistance:
                    endPt = ptXY
                    endDistance = distToPt
                    if distToPt > distToVertex:
                        endVertex = vertex
                    else:
                        endVertex = prevVertex

                    TOMsMessageLog.logMessage("In prepareSelfClosingBays: new endVertex: {}".format(endVertex), level=Qgis.Info)

                # break

            TOMsMessageLog.logMessage(
                "In prepareSelfClosingBays:two intersecting pts: startVertex: {}; endVertex: {}".format(startVertex, endVertex),
                level=Qgis.Info)

            # move along line ...
            #if not QgsGeometry.fromPointXY(QgsPointXY(startPt)).equals(QgsGeometry.fromPointXY(QgsPointXY(lineGeom.vertexAt(startVertex)))):
            #    # add start pt

            newLine.append(startPt)

            for i in range(startVertex, endVertex + 1, 1):
                newLine.append(line[i])

            #if not QgsGeometry.fromPointXY(QgsPointXY(endPt)).equals(QgsGeometry.fromPointXY(QgsPointXY(lineGeom.vertexAt(endVertex)))):
            #    # add end pt
            newLine.append(endPt)

            geomShapeID = 2  # half-on/half-off bay

        elif len(intesectingPts) == 0:
            # check whether or not shape is inside or outside the road casement.

            # move around shape and include any points that are within tolerance of the traceLayer

            newLine = inputLine  # return the original geometry

            #geomShapeID = 3  # on pavement bay

        else:
            newLine = inputLine, geomShapeID  # return the original geometry

        TOMsMessageLog.logMessage("In prepareSelfClosingBays: len newLine {}".format(len(newLine)), level=Qgis.Info)

        return newLine, geomShapeID

    def getDistanceToPoint(self, pointOnLine, line):
        # return distance along line for point
        # https://gis.stackexchange.com/questions/207724/how-to-get-distance-along-line-at-specific-point-in-qgis-pyqgis

        # step through line segments
        totalLength = 0.0
        for i in range(0, len(line)-1, 1):
            startVertex = i
            endVertex = i + 1

            lineSegment = QgsGeometry.fromPolylineXY([line[startVertex], line[endVertex]])
            TOMsMessageLog.logMessage("In getDistanceToPoint: i: {}; start: {}; end: {}".format(i, line[startVertex].asWkt(), line[endVertex].asWkt()),
                level=Qgis.Info)
            if lineSegment.intersects(QgsGeometry.fromPointXY(pointOnLine).buffer(0.1, 5)):
                lineSegmentToPoint = QgsGeometry.fromPolylineXY([line[startVertex], pointOnLine])
                totalLength += lineSegmentToPoint.length()
                break
            else:
                totalLength += lineSegment.length()

        TOMsMessageLog.logMessage("In getDistanceToPoint: totalLength: {}; vertex: {}".format(totalLength, startVertex), level=Qgis.Info)

        return totalLength, startVertex

    def checkRestrictionGeometryForDuplicatePoints(self, currRestrictionGeom, tolerance):
        # function to remove duplicate points or ones that are colinear (?) or at least ones that double back

        currRestrictionPtsList = currRestrictionGeom.asPolyline()
        nrVerticesInCurrRestriction = len(currRestrictionPtsList)

        vertexA = currRestrictionPtsList[0]
        shapeChanged = False
        nextVertexNr = 1
        # Now, consider each vertex of the sourceLineLayer in turn

        while true:

            vertexB = currRestrictionPtsList[nextVertexNr]

            if self.duplicatePoint(vertexA, vertexB):

                # do not want currVertex within new restriction
                currRestrictionPtsList.remove(currRestrictionPtsList[currVertexNr])
                nrVerticesInCurrRestriction = len(currRestrictionPtsList)
                shapeChanged = True
                #QgsMessageLog.logMessage("In checkLineForSelfOverlap. removing vertex" + str(currVertexNr),
                #                         tag="TOMs panel")
                #print ('In checkLineForSelfOverlap. removing vertex {}'.format(currVertexNr))
                if currVertexNr > 1:
                    currVertexNr = currVertexNr - 1

                vertexA = currRestrictionPtsList[currVertexNr - 1]

            else:

                vertexA = vertexB
                currVertexNr = currVertexNr + 1

        if shapeChanged:
            #QgsMessageLog.logMessage("In checkLineForSelfOverlap. changes written ... ",
            #                         tag="TOMs panel")
            #print ('In checkLineForSelfOverlap. changes written ...')
            newShape = QgsGeometry.fromPolylineXY(currRestrictionPtsList)
            return newShape

        return None

    def duplicatePoint(self, pointA, pointB):

        duplicate = False

        if pointA is None or pointB is None:
            duplicate = False
        elif math.sqrt((pointA.x() - pointB.x())**2 + ((pointA.y() - pointB.y())**2)) < DUPLICATE_POINT_DISTANCE:
            duplicate = True

        return duplicate

    def ensureVerticesNumberFromLineStart(self, nrVertices, vertex, prevVertex, nextVertex):

        # check to see whether or not the vertex is the last - and swap if required
        if vertex == nrVertices:
            vertex = 0
            nextVertex = 1
            prevVertex = -1

        return vertex, prevVertex, nextVertex

    def getVerticesWithinTolerance(self, restrictionline, traceLineLayer, tolerance):

        ptsList = []
        # check to see whether there were any points within tolerance
        for i in range(0, len(restrictionline) - 1, 1):
            pointOnTraceLine, traceLineFeature = generateGeometryUtils.findNearestPointOnLineLayer(
                restrictionline[i], traceLineLayer, tolerance)
            if pointOnTraceLine:
                ptsList.append(pointOnTraceLine.asPoint())

        if len(ptsList) >= 2:
            return QgsGeometry.fromPolylineXY(ptsList)

        return None

    def removeDanglingEndFromLoop(self, inputLine, tolerance=None):

        if not tolerance:
            tolerance = 0.5
        intesectingPts = []
        newLine = []
        #geomShapeID = 1

        # check proximity of end points
        line = inputLine

        currVertex = 0
        loop = False
        for i in range(len(inputLine)-1, 0, -1):
            TOMsMessageLog.logMessage("In removeDanglingEndFromLoop: checking for loop. considering vertex 0 and {}".format(i), level=Qgis.Info)
            if QgsGeometry.fromPointXY(inputLine[0]).distance(QgsGeometry.fromPointXY(inputLine[i])) < tolerance:
                loop = True
                break

        if not loop:
            TOMsMessageLog.logMessage("In removeDanglingEndFromLoop: no loop found", level=Qgis.Info)
            return inputLine

        # there is a loop forming at vertex i - create a new line from here and process
        TOMsMessageLog.logMessage("In removeDanglingEndFromLoop: preparing new geom - removing to vertex {}".format(i), level=Qgis.Info)
        outputLine = []
        for v in range(0, i+1, 1):
            outputLine.append(inputLine[v])

        return outputLine
