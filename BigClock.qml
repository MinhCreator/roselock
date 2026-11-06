import QtQuick
import Quickshell

Item {
    id: root

    property real size: 200
    readonly property bool stacked: Config.clockStyle === "stacked"
    readonly property string hh: Qt.formatDateTime(clk.date, Config.hour24 ? "HH" : "hh")
    readonly property string mm: Qt.formatDateTime(clk.date, "mm")
    readonly property rect tb: {
        fm.ascent;
        fm.descent;
        return fm.tightBoundingRect("0123456789");
    }
    readonly property bool measured: tb.height > 1
    readonly property real digitH: measured ? tb.height : size * 0.72
    readonly property real digitTop: measured ? fm.ascent + tb.y : size * 0.22
    readonly property real rowGap: Math.max(6, size * Config.clockGap)

    implicitWidth: stacked ? col.implicitWidth : inline.implicitWidth
    implicitHeight: stacked ? col.implicitHeight : inline.implicitHeight

    SystemClock {
        id: clk

        precision: SystemClock.Minutes
    }

    FontMetrics {
        id: fm

        font.family: Config.font
        font.pixelSize: root.size
        font.weight: Font.DemiBold
    }

    Column {
        id: col

        visible: root.stacked
        spacing: root.rowGap

        Item {
            x: (col.width - width) / 2
            width: hTxt.implicitWidth
            height: root.digitH

            Text {
                id: hTxt

                y: -root.digitTop
                text: root.hh
                color: Theme.s.primaryFixed
                font.family: Config.font
                font.pixelSize: root.size
                font.weight: Font.DemiBold
            }

        }

        Item {
            x: (col.width - width) / 2
            width: mTxt.implicitWidth
            height: root.digitH

            Text {
                id: mTxt

                y: -root.digitTop
                text: root.mm
                color: Theme.s.primaryFixedDim
                font.family: Config.font
                font.pixelSize: root.size
                font.weight: Font.DemiBold
            }

        }

    }

    Row {
        id: inline

        visible: !root.stacked

        Text {
            text: root.hh + ":"
            color: Theme.s.primaryFixed
            font.family: Config.font
            font.pixelSize: root.size * 0.62
            font.weight: Font.DemiBold
        }

        Text {
            text: root.mm
            color: Theme.s.primaryFixedDim
            font.family: Config.font
            font.pixelSize: root.size * 0.62
            font.weight: Font.DemiBold
        }

    }

}
