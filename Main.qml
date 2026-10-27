import QtQuick
import "components"

Item {
    id: root

    width: 1920
    height: 1080

    // ---- theme.conf ------------------------------------------------------
    readonly property string cBg: config.bg || "#000000"
    readonly property string cPanel: config.panel || "#0E0E0E"
    readonly property string cLine: config.line || "#2A2A2A"
    readonly property string cGrey: config.grey || "#8C8C8C"
    readonly property string cFg: config.fg || "#F2F2F2"
    readonly property string cRed: config.accent || "#D71921"

    readonly property bool clock24: String(config.clock24) !== "false"
    readonly property bool blinkOn: String(config.blink) !== "false"
    readonly property bool gridOn: String(config.grid) !== "false"
    readonly property bool orbOn: String(config.orb) !== "false"
    readonly property bool avatarDots: String(config.avatarDots) !== "false"
    readonly property string wallpaper: config.background || ""
    readonly property bool wallpaperDots: String(config.backgroundDots) !== "false"

    // ---- fonts -----------------------------------------------------------
    FontLoader { id: dotFont; source: "../fonts/Doto[ROND,wght].ttf" }
    FontLoader { id: uiFont; source: "../fonts/SpaceGrotesk-Regular.otf" }
    FontLoader { id: monoFont; source: "../fonts/SpaceMono-Regular.ttf" }

    readonly property string fDot: dotFont.name || "Doto"
    readonly property string fUi: uiFont.name || "Space Grotesk"
    readonly property string fMono: monoFont.name || "Space Mono"

    // ---- state -----------------------------------------------------------
    property alias password: pass.text
    property alias typedUser: userField.text

    property bool busy: false
    property bool fail: false
    property string info: ""

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    property bool blink: true
    property date now: new Date()
    property real t: 0
    property real wave: 0

    readonly property real s: Math.min(width / 1920, height / 1080)

    Repeater {
        id: users
        model: userModel

        Item {
            visible: false
            property string userName: model.name
            property string homeDir: model.homeDir
            property string avatar: model.icon
            property bool needsPassword: model.needsPassword
        }
    }

    Repeater {
        id: sessions
        model: sessionModel

        Item {
            visible: false
            property string sessionName: model.name
        }
    }

    readonly property var userItem: users.count > 0
        ? users.itemAt(Math.max(0, Math.min(userIndex, users.count - 1)))
        : null
    readonly property string userName: userItem ? userItem.userName : typedUser.trim()
    readonly property string userAvatar: userItem ? userItem.avatar : ""
    readonly property string userHome: userItem ? userItem.homeDir : ""
    readonly property bool needUsername: users.count === 0
    readonly property bool needPassword: userItem ? userItem.needsPassword : true

    readonly property string sessionName: sessions.count > 0
        ? sessions.itemAt(Math.max(0, Math.min(sessionIndex, sessions.count - 1))).sessionName
        : ""

    readonly property string layoutText: {
        if (!keyboard || !keyboard.layouts || keyboard.layouts.length === 0) return "";
        var layout = keyboard.layouts[keyboard.currentLayout];
        return layout ? (layout.shortName || layout.longName || "") : "";
    }

    readonly property string hourText: {
        var h = now.getHours();
        return clock24 ? String(h).padStart(2, "0") : String(h % 12 || 12);
    }
    readonly property string minuteText: String(now.getMinutes()).padStart(2, "0")

    readonly property string statusText: {
        if (busy) return "checking…";
        if (fail) return "wrong password · try again";
        if (info) return info;
        if (!needPassword) return "press enter to log in";
        return "enter password";
    }

    // ---- painting --------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: root.cBg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: root.needUsername ? userField.forceActiveFocus() : pass.forceActiveFocus()
    }

    Item {
        id: stage
        width: root.width / root.s
        height: root.height / root.s
        scale: root.s
        transformOrigin: Item.TopLeft

        Wallpaper {
            anchors.fill: parent
            source: root.wallpaper
            dots: root.wallpaperDots
            step: 12
            visible: root.wallpaper !== ""
            opacity: root.ph(0, 0.6)
        }

        Canvas {
            id: grid
            anchors.fill: parent
            visible: root.gridOn && root.wallpaper === ""
            opacity: root.ph(0, 0.6)

            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = root.cLine;
                for (var y = 16; y < height; y += 32) {
                    for (var x = 16; x < width; x += 32) {
                        ctx.beginPath();
                        ctx.arc(x, y, 1.5, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
            }
        }

        Canvas {
            id: orb
            x: stage.width - 720
            y: stage.height - 580
            width: 1100
            height: 1100
            visible: root.orbOn && root.wallpaper === ""
            opacity: root.ph(0, 0.6) * pulse

            property real pulse: 0.18

            SequentialAnimation on pulse {
                running: orb.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.24; duration: 4000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.18; duration: 4000; easing.type: Easing.InOutSine }
            }

            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var cx = 550, cy = 550, rr = 550, gx = 352, gy = 330, gr = 730;
                for (var y = 7; y < height; y += 14) {
                    for (var x = 7; x < width; x += 14) {
                        var dx = x - cx, dy = y - cy;
                        if (dx * dx + dy * dy > rr * rr) continue;
                        var d = Math.sqrt((x - gx) * (x - gx) + (y - gy) * (y - gy)) / gr;
                        var a = Math.max(0, 1 - d);
                        if (a <= 0) continue;
                        ctx.beginPath();
                        ctx.arc(x, y, 4.2, 0, Math.PI * 2);
                        ctx.fillStyle = "rgba(255,255,255," + a.toFixed(3) + ")";
                        ctx.fill();
                    }
                }
            }
        }

        // ---- date and clock ----------------------------------------------
        Lb {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 170
            px: 14
            family: root.fMono
            color: root.cGrey
            text: Qt.formatDate(root.now, "dddd · d MMMM")
            opacity: root.ph(0.15, 0.55)
            transform: Translate { y: 16 * (1 - root.ph(0.15, 0.55)) }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 230
            opacity: root.ph(0, 0.5)
            transform: Translate { y: -40 * (1 - root.ph(0, 0.5)) }

            Num {
                text: root.hourText
                family: root.fDot
                font.pixelSize: 400
            }
            Num {
                text: ":"
                family: root.fDot
                font.pixelSize: 400
                opacity: root.blink || !root.blinkOn ? 1 : 0.2
            }
            Num {
                text: root.minuteText
                family: root.fDot
                font.pixelSize: 400
            }
        }

        Lb {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 600
            family: root.fMono
            color: root.cGrey
            text: sddm.hostName || "glyph"
            opacity: root.ph(0.25, 0.65)
            transform: Translate { y: 16 * (1 - root.ph(0.25, 0.65)) }
        }

        // ---- top-right controls ------------------------------------------
        Row {
            anchors { right: parent.right; rightMargin: 44 }
            y: 36
            spacing: 18
            opacity: root.ph(0.45, 0.85)

            TopLabel {
                family: root.fMono
                normal: root.cGrey
                active: root.cFg
                shown: root.layoutText !== ""
                text: root.layoutText
                onClicked: root.cycleLayout()
            }
            TopLabel {
                family: root.fMono
                normal: root.cGrey
                active: root.cFg
                shown: sessions.count > 1
                text: "session · " + root.sessionName
                onClicked: root.cycleSession()
            }
            TopLabel {
                family: root.fMono
                normal: root.cGrey
                active: root.cFg
                shown: sddm.canReboot
                text: "reboot"
                onClicked: sddm.reboot()
            }
            TopLabel {
                family: root.fMono
                normal: root.cGrey
                active: root.cFg
                shown: sddm.canPowerOff
                text: "power off"
                onClicked: sddm.powerOff()
            }
        }

        // ---- avatar, name, password --------------------------------------
        Column {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 120
            }
            width: 700
            spacing: 16

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                height: 96
                opacity: root.ph(0.3, 0.7)
                transform: Translate { y: 24 * (1 - root.ph(0.3, 0.7)) }

                Ring {
                    anchors.fill: parent
                    n: 32
                    dot: 6
                    f: root.t > 0.35 ? 1 : 0
                    on: root.cFg
                    off: root.cLine
                }

                Avatar {
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    source: root.userAvatar
                    home: root.userHome
                    dots: root.avatarDots
                    step: 3
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: users.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (users.count > 1) root.cycleUser(1);
                        else pass.forceActiveFocus();
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                opacity: root.ph(0.4, 0.75)
                transform: Translate { y: 16 * (1 - root.ph(0.4, 0.75)) }

                Text {
                    visible: users.count > 1
                    text: "‹"
                    color: leftHover.containsMouse ? root.cFg : root.cGrey
                    font { family: root.fUi; pixelSize: 22 }
                    MouseArea {
                        id: leftHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cycleUser(-1)
                    }
                }

                Text {
                    visible: !root.needUsername
                    text: root.userName
                    color: root.cFg
                    font { family: root.fUi; pixelSize: 22 }
                }

                TextInput {
                    id: userField
                    visible: root.needUsername
                    width: 320
                    color: root.cFg
                    font { family: root.fUi; pixelSize: 22 }
                    horizontalAlignment: TextInput.AlignHCenter
                    selectionColor: root.cLine
                    selectedTextColor: root.cFg
                    cursorVisible: root.needUsername
                    focus: root.needUsername
                    onAccepted: pass.forceActiveFocus()
                }

                Text {
                    visible: users.count > 1
                    text: "›"
                    color: rightHover.containsMouse ? root.cFg : root.cGrey
                    font { family: root.fUi; pixelSize: 22 }
                    MouseArea {
                        id: rightHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cycleUser(1)
                    }
                }
            }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 58 + (380 - 58) * root.ph(0.5, 0.9)
                height: 58
                radius: 29
                clip: true
                opacity: root.ph(0.45, 0.6)
                color: root.cPanel
                border { width: 1; color: root.fail ? root.cRed : root.cLine }

                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    opacity: root.ph(0.75, 1)

                    Repeater {
                        model: Math.min(pass.text.length, 16)

                        Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: 11
                            height: 11
                            radius: 5.5
                            color: root.fail ? root.cRed : root.cFg
                            opacity: root.busy
                                && Math.abs(root.wave * (Math.min(pass.text.length, 16) + 2) - 1 - index) > 1.2
                                ? 0.3 : 1
                            NumberAnimation on scale {
                                from: 0.2; to: 1; duration: 180; easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 24
                        color: root.cRed
                        opacity: root.blink ? 1 : 0
                    }

                    Repeater {
                        model: Math.max(0, 6 - Math.min(pass.text.length, 16))

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 11
                            height: 11
                            radius: 5.5
                            color: root.cLine
                        }
                    }
                }

                TextInput {
                    id: pass
                    anchors.fill: parent
                    opacity: 0
                    echoMode: TextInput.Password
                    color: "transparent"
                    selectionColor: "transparent"
                    selectedTextColor: "transparent"
                    cursorVisible: false
                    readOnly: root.busy
                    focus: !root.needUsername
                    inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText
                        | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase

                    onAccepted: root.submit()

                    onTextChanged: {
                        if (root.fail) root.fail = false;
                        if (root.info) root.info = "";
                    }

                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right)
                                && text.length === 0) {
                            root.cycleUser(event.key === Qt.Key_Left ? -1 : 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            text = "";
                            root.fail = false;
                            event.accepted = true;
                        }
                    }
                }
            }

            Lb {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 700
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                opacity: root.ph(0.8, 1)
                family: root.fMono
                color: root.fail ? root.cRed : root.cGrey
                text: root.statusText
            }
        }

        // ---- caps lock notification--------------------------------------
        Lb {
            anchors { left: parent.left; leftMargin: 44; bottom: parent.bottom; bottomMargin: 44 }
            visible: keyboard && keyboard.capsLock
            family: root.fMono
            color: root.cFg
            text: "caps lock"
            opacity: root.ph(0.45, 0.85)
        }
    }

    // ---- clock, intro and network ---------------------------------------
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: 500
        running: root.blinkOn
        repeat: true
        onTriggered: root.blink = !root.blink
    }

    NumberAnimation on wave {
        running: root.busy
        from: 0
        to: 1
        duration: 700
        loops: Animation.Infinite
    }

    Timer {
        id: safety
        interval: 20000
        onTriggered: {
            if (root.busy) {
                root.busy = false;
                root.info = "no response · try again";
            }
        }
    }

    NumberAnimation {
        id: intro
        target: root
        property: "t"
        from: 0
        to: 1
        duration: 1100
        easing.type: Easing.OutQuart
    }

    Component.onCompleted: {
        intro.start();
        if (root.userIndex >= users.count) root.userIndex = 0;
        if (root.sessionIndex >= sessions.count) root.sessionIndex = 0;
        Qt.callLater(function() {
            if (root.needUsername) userField.forceActiveFocus();
            else pass.forceActiveFocus();
        });
    }

    // ---- function -----------------------------------------------------------
    function ph(a, b) {
        var x = Math.max(0, Math.min(1, (root.t - a) / (b - a)));
        return 1 - Math.pow(1 - x, 4);
    }

    function submit() {
        if (root.busy) return;
        if (root.needUsername && root.typedUser.trim() === "") {
            userField.forceActiveFocus();
            return;
        }
        if (!root.userName) return;

        root.busy = true;
        root.fail = false;
        root.info = "";
        safety.restart();
        sddm.login(root.userName, root.password, root.sessionIndex);
    }

    function cycleUser(delta) {
        if (users.count < 2) return;
        root.userIndex = (root.userIndex + delta + users.count) % users.count;
        root.password = "";
        root.fail = false;
        root.info = "";
        pass.forceActiveFocus();
    }

    function cycleSession() {
        if (sessions.count < 2) return;
        root.sessionIndex = (root.sessionIndex + 1) % sessions.count;
    }

    function cycleLayout() {
        if (!keyboard || !keyboard.layouts || keyboard.layouts.length < 2) return;
        keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length;
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            root.busy = false;
        }

        function onLoginFailed() {
            root.password = "";
            root.busy = false;
            root.fail = true;
            safety.stop();
            pass.forceActiveFocus();
        }

        function onInformationMessage(message) {
            root.busy = false;
            root.info = message;
            safety.stop();
        }

        function onSocketDisconnected() {
            root.busy = false;
            root.info = "lost connection to sddm";
            safety.stop();
        }
    }
}
