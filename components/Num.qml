import QtQuick

Text {
    id: root

    property string family: "Doto"

    readonly property real lead: -0.175 * font.pixelSize

    color: "#F2F2F2"
    font {
        family: root.family
        pixelSize: 44
        weight: Font.Black
        variableAxes: ({ "ROND": 100, "wght": 900 })
    }
    topPadding: lead
    bottomPadding: lead
}
