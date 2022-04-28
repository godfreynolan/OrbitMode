/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Controls.Private 1.0

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Slider {
    id:             _root
    implicitHeight: ScreenTools.implicitSliderHeight
    value:          0.5
    minimumValue:   0
    maximumValue:   1
    stepSize:       0.01
    orientation:    Qt.Vertical
    enabled:        false
    visible:        false
    onPressedChanged: resetValue()

    // Get active flight mode
    property var currentVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // Value indicator starts display from zero instead of min value
    property bool zeroCentered: true
    property bool displayValue: false

    function resetValue() {
        value = .5
    }

    style: SliderStyle {
        groove: Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth:          Math.round(ScreenTools.defaultFontPixelHeight * 4.5)
            implicitHeight:         Math.round(ScreenTools.defaultFontPixelHeight * 0.3)

            Rectangle {
                radius:         height / 2
                anchors.fill:   parent
                color:          qgcPal.button
                border.width:   1
                border.color:   qgcPal.buttonText
            }
        }

        handle: Rectangle {
            anchors.centerIn: parent
            color:          qgcPal.button
            border.color:   qgcPal.buttonText
            border.width:   1
            implicitWidth:  _radius * 2
            implicitHeight: _radius * 2
            radius:         _radius

            property real _radius: Math.round(_root.implicitHeight / 2)
        }
    }
}
