/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtLocation       5.3
import QtPositioning    5.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightMap     1.0

/// QGCMapCircle map visuals
Item {
    id: _root

    property var    mapControl                                                  ///< Map control to place item in
    property var    mapCircle                                                   ///< QGCMapCircle object
    property bool   interactive:        mapCircle ? mapCircle.interactive : 0   /// true: user can manipulate polygon
    property color  interiorColor:      "transparent"
    property real   interiorOpacity:    1
    property int    borderWidth:        2
    property color  borderColor:        "orange"

    property var    _circleComponent
    property var    _rectangleComponent
    property var    _topRotationIndicatorComponent
    property var    _bottomRotationIndicatorComponent
    property var    _dragHandlesComponent
    property real   _radius:            mapCircle ? mapCircle.radius.rawValue : 0

    function addVisuals() {
        if (!_circleComponent) {
            _circleComponent = circleComponent.createObject(mapControl)
            mapControl.addMapItem(_circleComponent)
            _rectangleComponent = rectangleComponent.createObject(mapControl)
            mapControl.addMapItem(_rectangleComponent)
        }
        if (!_topRotationIndicatorComponent) {
            _topRotationIndicatorComponent = rotationIndicatorComponent.createObject(mapControl, { "topIndicator": true })
            _bottomRotationIndicatorComponent = rotationIndicatorComponent.createObject(mapControl, { "topIndicator": false })
            mapControl.addMapItem(_topRotationIndicatorComponent)
            mapControl.addMapItem(_bottomRotationIndicatorComponent)
        }
    }

    function removeVisuals() {
        if (_circleComponent) {
            _circleComponent.destroy()
            _circleComponent = undefined
            _rectangleComponent.destroy()
            _rectangleComponent = undefined
        }
        if (_topRotationIndicatorComponent) {
            _topRotationIndicatorComponent.destroy()
            _bottomRotationIndicatorComponent.destroy()
            _topRotationIndicatorComponent = undefined
            _bottomRotationIndicatorComponent = undefined
        }
    }

    function addDragHandles() {
        if (!_dragHandlesComponent) {
            _dragHandlesComponent = dragHandlesComponent.createObject(mapControl)
        }
    }

    function removeDragHandles() {
        if (_dragHandlesComponent) {
            _dragHandlesComponent.destroy()
            _dragHandlesComponent = undefined
        }
    }

    function updateInternalComponents() {
        if (visible) {
            addVisuals()
            if (interactive) {
                addDragHandles()
            } else {
                removeDragHandles()
            }
        } else {
            removeVisuals()
            removeDragHandles()
        }
    }

    Component.onCompleted: {
        updateInternalComponents()
    }

    Component.onDestruction: {
        removeVisuals()
        removeDragHandles()
    }

    onInteractiveChanged:   updateInternalComponents()
    onVisibleChanged:       updateInternalComponents()

    Component {
        id: rotationIndicatorComponent

        MapQuickItem {
            visible: mapCircle.showRotation

            property bool topIndicator: true

            property real _rotationRadius: _radius

            function updateCoordinate() {
                coordinate = mapCircle.center.atDistanceAndAzimuth(_radius, topIndicator ? 0 : 180)
            }

            Component.onCompleted: updateCoordinate()

            on_RotationRadiusChanged: updateCoordinate()

            Connections {
                target:             mapCircle
                onCenterChanged:    updateCoordinate()
            }

            sourceItem: QGCColoredImage {
                anchors.centerIn:   parent
                width:              ScreenTools.defaultFontPixelHeight * 0.66
                height:             ScreenTools.defaultFontPixelHeight
                source:             "/qmlimages/arrow-down.png"
                color:              borderColor

                transform: Rotation {
                    origin.x:   width / 2
                    origin.y:   height / 2
                    angle:      (mapCircle.clockwiseRotation ? 1 : -1) * (topIndicator ? -90 : 90)
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  mapCircle.clockwiseRotation = !mapCircle.clockwiseRotation
                    visible:    mapCircle.interactive
                }
            }
        }
    }

    Component {
        id: circleComponent

        MapCircle {
            color:          interiorColor
            opacity:        interiorOpacity
            border.color:   borderColor
            border.width:   borderWidth
            center:         mapCircle.center
            radius:         _radius
        }
    }

    // Get the location offset for the radius
    Location {
        id: lineComponent
        property real radius:   _radius
        property var lat:       mapCircle.center.latitude
        property var lon:       mapCircle.center.longitude
        coordinate:             QtPositioning.coordinate(lat, lon + radius/(111.32 * 1000 * Math.cos(lat * (Math.PI / 180))))
    }

    // Line for the radius
    Component {
        id: rectangleComponent

        MapRectangle {
            color:          interiorColor
            opacity:        interiorOpacity
            border.color:   borderColor
            border.width:   borderWidth
            topLeft:        mapCircle.center
            bottomRight:    lineComponent.coordinate
        }
    }

    // Show Radius while dragging
    Component {
        id: dragRadiusComponent

        MapQuickItem {
            id:             radiusMapQuickItem
            anchorPoint.x:  dragRadius.width / 2
            anchorPoint.y:  dragRadius.height / 2
            z:              QGroundControl.zOrderMapItems + 2

            sourceItem: Rectangle {
                id:         dragRadius
                width:      radiusNumber.width + 10
                height:     radiusNumber.height + 10
                border.color: borderColor
                border.width: borderWidth
                color:      "white"

                Text {
                    id:                         radiusNumber
                    text: {                     if (_radius < 1)
                                                    (1 * 3.28084).toFixed(4) + " ft"
                                                else if (_radius > 100)
                                                    (100 * 3.28084).toFixed(4) + " ft"
                                                else
                                                    (_radius * 3.28084).toFixed(4) + " ft"
                    }
                    anchors.horizontalCenter:   dragRadius.horizontalCenter
                    anchors.verticalCenter:     dragRadius.verticalCenter
                }
            }
        }
    }

    Component {
        id: dragHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  dragHandle.width / 2
            anchorPoint.y:  dragHandle.height / 2
            z:              QGroundControl.zOrderMapItems + 2

            sourceItem: Rectangle {
                id:         dragHandle
                width:      ScreenTools.defaultFontPixelHeight * 1.5
                height:     width
                radius:     width / 2
                color:      "white"
                opacity:    .90
            }
        }
    }

    Component {
        id: centerDragAreaComponent

        MissionItemIndicatorDrag {
            mapControl: _root.mapControl

            onItemCoordinateChanged: mapCircle.center = itemCoordinate
        }
    }

    Component {
        id: radiusDragAreaComponent

        MissionItemIndicatorDrag {
            mapControl: _root.mapControl

            onItemCoordinateChanged: mapCircle.radius.rawValue = mapCircle.center.distanceTo(itemCoordinate)        }
    }

    Component {
        id: dragHandlesComponent

        Item {
            property var centerDragHandle
            property var centerDragArea
            property var radiusDragHandle
            property var radiusDragArea
            property var showRadius
            property var radiusDragCoord:       QtPositioning.coordinate()
            property var circleCenterCoord:     mapCircle.center
            property var outsideCircleCoord:    QtPositioning.coordinate(mapCircle.center.latitude, mapCircle.center.longitude + (_radius/2)/(111.32 * 1000 * Math.cos(mapCircle.center.latitude * (Math.PI / 180))))
            property real circleRadius:         _radius

            function calcRadiusDragCoord() {
                radiusDragCoord = mapCircle.center.atDistanceAndAzimuth(circleRadius, 90)
            }

            onCircleCenterCoordChanged: calcRadiusDragCoord()
            onCircleRadiusChanged:      calcRadiusDragCoord()

            Component.onCompleted: {
                calcRadiusDragCoord()
                radiusDragHandle = dragHandleComponent.createObject(mapControl)
                radiusDragHandle.coordinate = Qt.binding(function() { return radiusDragCoord })
                mapControl.addMapItem(radiusDragHandle)
                radiusDragArea = radiusDragAreaComponent.createObject(mapControl, { "itemIndicator": radiusDragHandle, "itemCoordinate": radiusDragCoord })
                centerDragHandle = dragHandleComponent.createObject(mapControl)
                centerDragHandle.coordinate = Qt.binding(function() { return circleCenterCoord })
                mapControl.addMapItem(centerDragHandle)
                showRadius = dragRadiusComponent.createObject(mapControl, { "visible": _root.centerDragHandleVisible })
                showRadius.coordinate = Qt.binding(function() { return outsideCircleCoord })
                mapControl.addMapItem(showRadius)
                centerDragArea = centerDragAreaComponent.createObject(mapControl, { "itemIndicator": centerDragHandle, "itemCoordinate": circleCenterCoord })
            }

            Component.onDestruction: {
                centerDragHandle.destroy()
                centerDragArea.destroy()
                radiusDragHandle.destroy()
                radiusDragArea.destroy()
                showRadius.destroy()
            }
        }
    }
}
