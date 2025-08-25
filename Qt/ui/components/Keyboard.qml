import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: kb
    // ====== API ======
    property var  target: null       // TextField/TextArea nhận text
    property bool opened: true
    property bool shift: false
    property bool symbols: false

    // ====== Style ======
    property color bgColor: "#D9DCE2"
    property color rowBg: "#CDD2DA"
    property real  keyH: 44
    property real  keySpacing: 6
    property real  keyRadius: 6

    focus: false
    width: parent ? parent.width : 360
    height: opened ? 200 : 0
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

    Rectangle { anchors.fill: parent; color: bgColor }

    // ====== Nút phím ======
    component Key: Control {
        id: key
        property string label: ""
        property string value: label
        property bool big: false
        property bool accent: false
        signal pressed(string v)

        focusPolicy: Qt.NoFocus
        implicitHeight: keyH
        implicitWidth: big ? 96 : 32

        background: Rectangle {
            radius: keyRadius
            color: key.accent ? "#B0B6BF" : "#E6E8ED"
            border.color: "#AAB0B8"
        }
        contentItem: Label {
            text: key.label
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onPressed: rep.start()
            onReleased: { rep.stop(); key.pressed(key.value) }
            onCanceled: rep.stop()
        }
        Timer {
            id: rep
            interval: 400; repeat: true
            onTriggered: {
                if (interval === 400) interval = 70; // delay ban đầu trước auto-repeat
                key.pressed(key.value)
            }
            onRunningChanged: if (!running) interval = 400
        }
    }

    // ====== Data ======
    readonly property var row1Letters: ["Q","W","E","R","T","Y","U","I","O","P"]
    readonly property var row2Letters: ["A","S","D","F","G","H","J","K","L"]
    readonly property var row3Letters: ["Z","X","C","V","B","N","M"]

    readonly property var row1Symbols: ["1","2","3","4","5","6","7","8","9","0"]
    readonly property var row2Symbols: ["~","@","#","$","%","&","*","(",")"]
    readonly property var row3Symbols: [".",",","?","^",":","/","\\","“","”"]

    // ====== Helpers ======
    function refocus() {
        if (target && target.forceActiveFocus) target.forceActiveFocus();
    }

    // CHỈNH: tự ghép chuỗi để hoạt động cả khi TextField.readOnly: true
    function insertText(txt) {
        refocus();
        if (!target) return;

        let t = target.text || "";
        let cur = target.cursorPosition ?? 0;
        let selStart = target.selectionStart ?? cur;
        let selEnd   = target.selectionEnd   ?? cur;

        if (selEnd > selStart) {
            t = t.slice(0, selStart) + t.slice(selEnd);
            cur = selStart;
        }

        t = t.slice(0, cur) + txt + t.slice(cur);
        target.text = t;
        target.cursorPosition = cur + txt.length;

        if (shift && !symbols) shift = false;
    }

    function backspace() {
        refocus();
        if (!target) return;

        let t = target.text || "";
        let cur = target.cursorPosition ?? 0;
        let selStart = target.selectionStart ?? cur;
        let selEnd   = target.selectionEnd   ?? cur;

        if (selEnd > selStart) {
            t = t.slice(0, selStart) + t.slice(selEnd);
            target.text = t;
            target.cursorPosition = selStart;
            return;
        }

        if (cur > 0) {
            t = t.slice(0, cur - 1) + t.slice(cur);
            target.text = t;
            target.cursorPosition = cur - 1;
        }
    }

    function returnKey() {
        refocus();
        if (!target) return;
        insertText("\n");
        opened = false;
        target.focus = false;
    }

    // ====== Layout ======
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: keySpacing

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: keyH
            radius: keyRadius; color: rowBg
            RowLayout {
                anchors.fill: parent; anchors.margins: keySpacing; spacing: keySpacing
                Repeater {
                    model: kb.symbols ? kb.row1Symbols : kb.row1Letters
                    delegate: Key {
                        label: kb.shift && !kb.symbols ? modelData.toUpperCase() : modelData
                        value: kb.shift && !kb.symbols ? modelData.toUpperCase() : modelData
                        onPressed: kb.insertText(value)
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: keyH
            radius: keyRadius; color: rowBg
            RowLayout {
                anchors.fill: parent; anchors.margins: keySpacing; spacing: keySpacing
                Item { Layout.preferredWidth: 12 }
                Repeater {
                    model: kb.symbols ? kb.row2Symbols : kb.row2Letters
                    delegate: Key {
                        label: kb.shift && !kb.symbols ? modelData.toUpperCase() : modelData
                        value: kb.shift && !kb.symbols ? modelData.toUpperCase() : modelData
                        onPressed: kb.insertText(value)
                        Layout.fillWidth: true
                    }
                }
                Item { Layout.preferredWidth: 12 }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: keyH
            radius: keyRadius; color: rowBg
            RowLayout {
                anchors.fill: parent; anchors.margins: keySpacing; spacing: keySpacing

                Key {
                    label: kb.symbols ? "abc" : "\u21E7"
                    value: ""
                    accent: true
                    onPressed: {
                        if (kb.symbols) kb.symbols = false;
                        else kb.shift = !kb.shift;
                    }
                    Layout.preferredWidth: 56
                }

                Repeater {
                    model: kb.symbols ? kb.row3Symbols : kb.row3Letters
                    delegate: Key {
                        label: kb.shift && !kb.symbols ? modelData.toUpperCase() : modelData
                        value: kb.shift && !kb.symbols ? modelData.toUpperCase() : modelData
                        onPressed: kb.insertText(value)
                        Layout.fillWidth: true
                    }
                }

                Key {
                    label: "\u232B"  // ⌫
                    value: ""
                    accent: true
                    onPressed: kb.backspace()
                    Layout.preferredWidth: 56
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: keyH + 8
            radius: keyRadius; color: rowBg
            RowLayout {
                anchors.fill: parent; anchors.margins: keySpacing; spacing: keySpacing

                Key {
                    label: kb.symbols ? "abc" : "123"
                    value: ""
                    accent: true
                    onPressed: { kb.symbols = !kb.symbols; kb.shift = false }
                    Layout.preferredWidth: 64
                }

                Key {
                    label: kb.symbols ? "Space" : "space"
                    value: " "
                    big: true
                    onPressed: kb.insertText(" ")
                    Layout.fillWidth: true
                }

                Key {
                    label: "return"
                    value: "\n"
                    accent: true
                    big: true
                    onPressed: kb.returnKey()
                    Layout.preferredWidth: 84
                }
            }
        }
    }
}
