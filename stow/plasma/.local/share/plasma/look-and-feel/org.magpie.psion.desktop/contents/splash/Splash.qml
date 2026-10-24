import QtQuick

Rectangle {
    id: background
    anchors.centerIn: parent
    color: "#1f1f1f"

    // Rectangle {
    //     anchors.fill: parent
    //     color: "#44000000"
    // }

    Rectangle {
        id: groove
        width: 360
        height: 12
        anchors.centerIn: parent
        color: "#121212"

        Rectangle {
            id: block
            height: 8
            width: 48
            anchors.verticalCenter: parent.verticalCenter
            color: "#817563"

            SequentialAnimation on x {
                id: anim
                loops: Animation.Infinite

                NumberAnimation  {
                    from: 0
                    to: groove.width - block.width
                    duration: 1500
                    easing.type: Easing.OutQuad
                }
                NumberAnimation  {
                    from: groove.width - block.width
                    to: 0
                    duration: 1500
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
