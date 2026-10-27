import QtQuick

Item {
    id: root

    property string source: ""
    property bool dots: true
    property real step: 12

    Image {
        id: image
        source: root.source
        asynchronous: true
        visible: false
        sourceSize: Qt.size(2560, 0)
        onStatusChanged: canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        opacity: 0.55

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            if (root.source === "" || image.status !== Image.Ready)
                return;

            var w = width, h = height;
            var iw = image.implicitWidth, ih = image.implicitHeight;
            var sa = w / h, ia = iw / ih;
            var sx, sy, sw, sh;
            if (ia > sa) { sh = ih; sw = ih * sa; sx = (iw - sw) / 2; sy = 0; }
            else { sw = iw; sh = iw / sa; sx = 0; sy = (ih - sh) / 2; }
            ctx.drawImage(image, sx, sy, sw, sh, 0, 0, w, h);

            if (root.dots) {
                ctx.globalCompositeOperation = "destination-in";
                var p = Math.max(4, root.step);
                var r = p * 0.3;
                for (var y = p / 2; y < h; y += p) {
                    for (var x = p / 2; x < w; x += p) {
                        ctx.beginPath();
                        ctx.arc(x, y, r, 0, Math.PI * 2);
                        ctx.fillStyle = "#fff";
                        ctx.fill();
                    }
                }
            }
        }
    }
}
