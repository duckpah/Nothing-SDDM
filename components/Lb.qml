import QtQuick

Text {
    id: root

    property real px: 12
    property string family: "Space Mono"

    color: "#8C8C8C"
    font {
        family: root.family
        pixelSize: root.px
        letterSpacing: root.px * 0.14
        capitalization: Font.AllUppercase
    }
}
