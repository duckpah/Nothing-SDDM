import QtQuick

Item {
    id: root

    property alias text: label.text
    property string family: "Space Mono"
    property color normal: "#8C8C8C"
    property color active: "#F2F2F2"
    property bool shown: true

    signal clicked()

    visible: shown
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Lb {
        id: label
        anchors.centerIn: parent
        family: root.family
        color: hover.hovered ? root.active : root.normal
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
