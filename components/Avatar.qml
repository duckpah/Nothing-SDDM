import QtQuick

Item {
    id: root

    property string source: ""
    property string home: ""
    property bool dots: true
    property real step: 3

    readonly property string homeFace: home
        ? "file://" + home.split("/").map(encodeURIComponent).join("/") + "/.face"
        : ""

    // SDDM hands every user the generic /usr/share/sddm/faces/.face.icon when
    // there is no real avatar; treat it as "no avatar" and try ~/.face first.
    readonly property string candidate: {
        if (source && source.indexOf("/.face.icon") === -1) return source;
        return homeFace;
    }

    onCandidateChanged: canvas.requestPaint()

    Image {
        id: image
        source: root.candidate
        asynchronous: true
        visible: false
        sourceSize: Qt.size(256, 0)
        onStatusChanged: canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var w = width, h = height, cx = w / 2, cy = h / 2, r = Math.min(w, h) / 2;
            ctx.save();
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.clip();

            if (image.status === Image.Ready && root.candidate !== "") {
                // PreserveAspectCrop, like the shell's Art.qml.
                var iw = image.implicitWidth, ih = image.implicitHeight;
                var sa = w / h, ia = iw / ih;
                var sx, sy, sw, sh;
                if (ia > sa) { sh = ih; sw = ih * sa; sx = (iw - sw) / 2; sy = 0; }
                else { sw = iw; sh = iw / sa; sx = 0; sy = (ih - sh) / 2; }
                ctx.drawImage(image, sx, sy, sw, sh, 0, 0, w, h);
            } else {
                // Art.qml fallback: a conical white→black gradient made of dots.
                var p0 = Math.max(2, root.step);
                var d0 = p0 * 0.3;
                for (var y0 = p0 / 2; y0 < h; y0 += p0) {
                    for (var x0 = p0 / 2; x0 < w; x0 += p0) {
                        var t = Math.atan2(y0 - cy, x0 - cx) / (Math.PI * 2) + 0.14;
                        t = t - Math.floor(t);
                        var l = conical(t);
                        ctx.beginPath();
                        ctx.arc(x0, y0, d0, 0, Math.PI * 2);
                        ctx.fillStyle = "rgba(255,255,255," + l.toFixed(3) + ")";
                        ctx.fill();
                    }
                }
            }

            if (root.dots) {
                // destination-in keeps the picture only inside the dot grid.
                ctx.globalCompositeOperation = "destination-in";
                var p = Math.max(2, root.step);
                var d = p * 0.3;
                for (var y = p / 2; y < h; y += p) {
                    for (var x = p / 2; x < w; x += p) {
                        ctx.beginPath();
                        ctx.arc(x, y, d, 0, Math.PI * 2);
                        ctx.fillStyle = "#fff";
                        ctx.fill();
                    }
                }
            }

            ctx.restore();
        }
    }

    // ConicalGradient stops from Art.qml: white, #444, #ddd, #111, #bbb, white.
    function conical(t) {
        var stops = [[0, 1], [0.2, 0.267], [0.4, 0.867], [0.6, 0.067], [0.8, 0.733], [1, 1]];
        for (var i = 1; i < stops.length; ++i) {
            if (t <= stops[i][0]) {
                var a = stops[i - 1], b = stops[i];
                var k = (t - a[0]) / (b[0] - a[0]);
                return a[1] + (b[1] - a[1]) * k;
            }
        }
        return 1;
    }
}
