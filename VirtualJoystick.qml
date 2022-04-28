/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick 2.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controllers   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0

Item {
    // The following properties must be passed in from the Loader
    // property bool autoCenterThrottle - true: throttle will snap back to center when released

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    FactPanelController {
        id: controller
    }

    //calulate relative azimuth between center of orbit and drone
    function calcAzimuth(){
        var phi = 0;
        var phi2 = 0;
        var x = [0,0];
        var y = [0,0];
        var pi = 3.141592265358973;

        //coordinate of drone
        x[0]=Math.cos(2*pi-(_activeVehicle.heading.value/180.0*pi-pi/2.0));//_activeVehicle.longitude;
        y[0]=Math.sin(2*pi-(_activeVehicle.heading.value/180.0*pi-pi/2.0));//_activeVehicle.latitude;

        //coordinate of circle center
        x[1]=_activeVehicle.orbitMapCircle.center.longitude-_activeVehicle.longitude;
        y[1]=_activeVehicle.orbitMapCircle.center.latitude-_activeVehicle.latitude;

        //0:pi
        phi= Math.acos((x[0]*x[1]+y[0]*y[1])/( Math.sqrt(x[0]*x[0]+y[0]*y[0])*Math.sqrt(x[1]*x[1]+y[1]*y[1])  )  );
                var w = x[0]*y[1]-x[1]*y[0];
                if (w<0){
                    phi=2*pi-phi;
                }

        //now handle crossovers
        if(Math.abs(phi)>Math.abs(2*pi-phi)){
            if(phi>0){
                phi=phi-2*pi;
            }
        }
        else if (Math.abs(phi)>Math.abs(phi+2*pi)){
            phi=phi+2*pi;
        }

        //convert to degrees
        phi = 180.0/pi*phi ;

        return (phi);
    }

    function saturation(x, lower, upper){
        if(x>upper){
            x=upper;
        }
        else if (x<lower){
            x=lower;
        }
    return (x);
    }

    //proportional feedback controller to compute value, takes in ref, y, and gain (constant), returns control input
    function uKp(ref, y, P_gain){
        var U_c=0;
        var e=0;
        var eMAX = 30;
        var eMIN = -30;
        var uMAX = 0.7;
        var uMIN = -0.7;

        e=ref-y;

        e = saturation(e,eMIN, eMAX);

        U_c =P_gain*e;

        //saturation
        U_c = saturation(U_c, uMIN, uMAX);

        return(U_c);
    }


    Timer {
        interval:   40  // 25Hz, same as real joystick rate
        running:    QGroundControl.settingsManager.appSettings.virtualJoystick.value && _activeVehicle
        repeat:     true
        onTriggered: {

            if (_activeVehicle && (_activeVehicle.flightMode === "Orbit")) {

                //  console.log(yawSlider.value-calcAzimuth(),", ", uKp(yawSlider.value,calcAzimuth(),0.015))
                //.015 - better still weak and no oscillation//.03 tighter but some oscillation
                _activeVehicle.virtualTabletJoystickValue(rightStick.xAxis, rightStick.yAxis,uKp(yawSlider.value,calcAzimuth(),0.025), pitchSlider.value)

            } else if (_activeVehicle) {
                _activeVehicle.virtualTabletJoystickValue(rightStick.xAxis, rightStick.yAxis, leftStick.xAxis, leftStick.yAxis)
            } else {
            }
        }
    }

    QGCVerticalSlider {
        id:                     pitchSlider
        enabled:                _activeVehicle && (_activeVehicle.flightMode === "Orbit")
        visible:                _activeVehicle && (_activeVehicle.flightMode === "Orbit")
        anchors.left:           parent.left
        anchors.bottom:         parent.bottom
        height:                 parent.height
        width:                  parent.height/2
    }

    QGCHorizontalSlider {
        id:                     yawSlider
        enabled:                _activeVehicle && (_activeVehicle.flightMode === "Orbit")
        visible:                _activeVehicle && (_activeVehicle.flightMode === "Orbit")
        anchors.left:           pitchSlider.right
        anchors.leftMargin:     20
        width:                  parent.height
        height:                 parent.height/2
        value:                  0

        onValueChanged: {
        }

        QGCButton {
            id:                         resetZero
            enabled:                    _activeVehicle && (_activeVehicle.flightMode === "Orbit")
            visible:                    _activeVehicle && (_activeVehicle.flightMode === "Orbit")
            anchors.top:                yawSlider.bottom
            anchors.horizontalCenter:   yawSlider.horizontalCenter
            height:                     parent.height/2
            text:                       "Reset to 0"
            onClicked: {
                                        yawSlider.value = 0
            }
        }
    }

    JoystickThumbPad {
        id:                     leftStick
        enabled:                !(_activeVehicle && (_activeVehicle.flightMode === "Orbit"))
        visible:                !(_activeVehicle && (_activeVehicle.flightMode === "Orbit"))
        anchors.leftMargin:     xPositionDelta
        anchors.bottomMargin:   -yPositionDelta
        anchors.left:           parent.left
        anchors.bottom:         parent.bottom
        width:                  parent.height
        height:                 parent.height
        yAxisPositiveRangeOnly: _activeVehicle && !_activeVehicle.rover
        yAxisReCenter:          autoCenterThrottle
    }
    JoystickThumbPad {
        id:                     rightStick
        anchors.rightMargin:    -xPositionDelta
        anchors.bottomMargin:   -yPositionDelta
        anchors.right:          parent.right
        anchors.bottom:         parent.bottom
        width:                  parent.height
        height:                 parent.height
    }
}
