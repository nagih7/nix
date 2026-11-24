// The dictionary popup: a layer-shell surface placed at the mouse, showing
// the HTML that render.py produced.
//
// Everything it needs arrives in one JSON file whose path is in
// $DICT_POPUP_FILE — geometry, the screen to appear on, and the document
// itself. One file rather than a pile of environment variables because the
// document is 30-40 KB of markup, and reading it here keeps dict-popup free
// of any QML-quoting concerns.
//
// Two non-obvious choices, both the result of watching it get them wrong:
//
//   Flickable + Text, not ScrollView + TextEdit. A TextEdit owns a text
//   cursor and scrolls itself to it, and a 34 KB rich-text document relayouts
//   after its first pass, so the popup kept opening part-way down the second
//   dictionary instead of at the headword. Setting contentY back to 0 raced
//   the relayout. A Text item has no cursor, so the position is exactly what
//   is set here. The cost is losing mouse selection of the text.
//
//   margins, not a position. A layer surface is placed by anchoring it to an
//   edge and pushing it in, and those margins are measured from the *usable*
//   area — inside whatever the bar has reserved — so dict-popup computes them
//   against hyprctl's reserved values rather than raw screen coordinates.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Effects

ShellRoot {
    id: root

    property var doc: ({})

    FileView {
        id: src
        path: Quickshell.env("DICT_POPUP_FILE") ?? ""
        blockLoading: true
    }

    Component.onCompleted: {
        try {
            root.doc = JSON.parse(src.text());
        } catch (e) {
            // Nothing useful to show, and a half-drawn popup is worse than
            // none, so leave immediately rather than paint an empty box.
            console.error("dict-popup: unreadable payload:", e);
            Qt.quit();
        }
    }

    PanelWindow {
        id: win
        visible: Object.keys(root.doc).length > 0

        // Matched by the Hyprland layer_rule that blurs behind the popup;
        // without that rule the translucent background is merely see-through
        // and the text behind it reads straight through the definition.
        WlrLayershell.namespace: root.doc.namespace ?? "dict-popup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        screen: Quickshell.screens.find(s => s.name === root.doc.screen) ?? null

        anchors.top: true
        anchors.left: true
        margins.top: root.doc.marginTop ?? 0
        margins.left: root.doc.marginLeft ?? 0

        // The surface is the card plus shadowPad on every side. A layer
        // surface clips to its own bounds, so a shadow drawn at the card's
        // edge has nowhere to fall unless that room exists; dict-popup
        // already subtracted the same pad from the margins, so the *card*
        // still lands under the cursor.
        implicitWidth: root.doc.surfaceWidth ?? root.doc.width ?? 520
        implicitHeight: root.doc.surfaceHeight ?? root.doc.height ?? 620

        // The shadow is cast by a stand-in rather than by the card itself.
        // Running the card through layer.effect would mean drawing the
        // interactive content *through* the effect, and the scroll area stops
        // behaving. So an invisible rectangle of the same shape feeds the
        // effect, and the real card is drawn on top of the result.
        //
        // Qt rather than Hyprland because a layer_rule can blur what is
        // behind a surface but cannot cast a shadow for it.
        // RectangularShadow, not MultiEffect. MultiEffect draws its *source*
        // as well as the shadow, and the source must be opaque for there to
        // be a shadow at all (it is derived from alpha) — so an opaque black
        // stand-in ended up visible through the translucent card, as a darker
        // rectangle inside a lighter rim. That is the "two layers" this used
        // to show. RectangularShadow takes a shape rather than a source and
        // draws only the shadow, so there is nothing to bleed through.
        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            color: root.doc.shadowColor ?? "#A0000000"
            blur: root.doc.shadowBlur ?? 40
            spread: root.doc.shadowSpread ?? 0
            offset: Qt.vector2d(0, root.doc.shadowOffsetY ?? 8)
            opacity: root.doc.shadowOpacity ?? 1.0
            visible: root.doc.shadowEnabled ?? false
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: root.doc.width ?? 520
            height: root.doc.height ?? 620
            radius: root.doc.radius ?? 18
            color: root.doc.background ?? Qt.rgba(0.11, 0.10, 0.12, 0.82)
            border.width: root.doc.borderWidth ?? 1
            border.color: root.doc.border ?? Qt.rgba(1, 1, 1, 0.10)

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: root.doc.padding ?? 18
                clip: true
                contentWidth: width
                // Column, so height (not implicitHeight) is the laid-out
                // total, and it grows when a section is expanded.
                contentHeight: body.height
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: flick.contentHeight > flick.height
                        ? ScrollBar.AsNeeded
                        : ScrollBar.AlwaysOff
                }

                // One item per dictionary rather than one Text for the whole
                // document, so each can be held to a line budget and expanded
                // on its own. That is how Dictionary.app does it: it cuts
                // mid-token ("…| [with more"), so the limit is geometric, and
                // Qt's maximumLineCount/truncated are the same mechanism.
                Column {
                    id: body
                    width: flick.width
                    spacing: 0

                    // "From the clipboard — nothing was selected", when that
                    // is how the word was found.
                    Text {
                        visible: (root.doc.note ?? "") !== ""
                        width: parent.width
                        wrapMode: Text.Wrap
                        color: root.doc.foreground || "#ECECEC"
                        opacity: 0.6
                        font.family: root.doc.fontFamily || Qt.application.font.family
                        text: root.doc.note ?? ""
                        bottomPadding: 8
                    }

                    Repeater {
                        model: root.doc.sections ?? []

                        Column {
                            id: section
                            width: body.width
                            spacing: 0

                            property bool expanded: false

                            // The heading, with the rule running off to its
                            // right — "English ─────────", as macOS sets it.
                            //
                            // This is laid out in QML, not in the rich text,
                            // and that is the whole reason it now works. In
                            // rich text it was unreachable: a two-cell table
                            // either collapsed the rule to a dash or squeezed
                            // the name to one character per line, `nowrap`
                            // was ignored, an <hr> is always full width, and a
                            // measured run of ─ glyphs needs font metrics
                            // Python cannot see. Once each dictionary became
                            // its own item for the truncation work, the
                            // heading stopped being rich text and a Row with
                            // a Rectangle does it exactly.
                            Row {
                                visible: (modelData.name ?? "") !== ""
                                width: parent.width
                                spacing: 10
                                topPadding: 10
                                bottomPadding: 6

                                Text {
                                    id: label
                                    text: modelData.name ?? ""
                                    // The name is a dictionary title or a
                                    // sectionLabels value, and Text defaults
                                    // to AutoText — which sniffs for markup.
                                    // Nothing in the data has angle brackets
                                    // today; this makes sure it could not
                                    // matter if one did.
                                    textFormat: Text.PlainText
                                    color: root.doc.section ?? "#BFBFBF"
                                    font.family: root.doc.labelFont || Qt.application.font.family
                                    font.pixelSize: root.doc.sectionPx ?? 18
                                }

                                Rectangle {
                                    width: parent.width - label.width - parent.spacing
                                    height: 1
                                    color: root.doc.rule ?? "#4A4A4A"
                                    // Sits on the label's optical centre
                                    // rather than its baseline.
                                    anchors.verticalCenter: label.verticalCenter
                                }
                            }

                            // Clipped to a height, not limited to a line
                            // count. Text.maximumLineCount, Text.lineCount
                            // and Text.truncated do not work with
                            // textFormat: RichText — that path lays out
                            // through QTextDocument, where Qt does not
                            // support them (the same reason elide cannot be
                            // used with rich text). Setting
                            // maximumLineCount: 5 simply did nothing.
                            //
                            // maxLines × line height is the same budget
                            // expressed in pixels, and clipping a container
                            // is honoured regardless of text format.
                            readonly property real lineH:
                                (root.doc.fontPx ?? 14) * ((root.doc.lineHeightPct ?? 140) / 100)
                            readonly property real budget:
                                (root.doc.maxLines ?? 0) > 0
                                    ? root.doc.maxLines * lineH
                                    : Number.MAX_VALUE
                            readonly property bool clipped:
                                entry.implicitHeight > budget + 1

                            Item {
                                width: parent.width
                                height: (section.expanded || !section.clipped)
                                    ? entry.implicitHeight
                                    : section.budget
                                clip: true

                                Text {
                                    id: entry
                                    width: parent.width
                                    textFormat: Text.RichText
                                    wrapMode: Text.Wrap
                                    color: root.doc.foreground || "#ECECEC"
                                    // || not ??: fontFamily defaults to the
                                    // empty string, not null, and ?? only
                                    // catches null/undefined — so Qt was
                                    // handed font.family: "" and fell back to
                                    // a serif face instead of the sans
                                    // intended.
                                    font.family: root.doc.fontFamily || Qt.application.font.family
                                    text: "<html><head><style>" + (root.doc.style ?? "")
                                          + "</style></head><body>"
                                          + (modelData.html ?? "")
                                          + "</body></html>"
                                }
                            }

                            // Only when something is actually hidden, so a
                            // short entry gets no stray link.
                            Text {
                                visible: section.clipped && !section.expanded
                                color: root.doc.accent ?? "#4DA3FF"
                                font.family: root.doc.fontFamily || Qt.application.font.family
                                font.bold: true
                                font.pixelSize: root.doc.fontPx ?? 14
                                text: "more"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: section.expanded = true
                                }
                            }
                        }
                    }
                }
            }
        }

        // q matches the terminal backend's pager, so the muscle memory is the
        // same whichever one is in use.
        Shortcut {
            sequences: ["Escape", "q"]
            onActivated: Qt.quit()
        }

        // Click anywhere else and it goes away, like the macOS popover.
        //
        // This also fixes a worse problem than the missing convenience. The
        // surface takes keyboardFocus: Exclusive, so until it closed, every
        // keystroke went to it — click back into an editor and type, and the
        // characters landed nowhere (or on `q`, which closed the popup). The
        // grab makes losing the pointer the same event as pressing Escape.
        //
        // Hyprland-specific, which is fine: the geometry in dict-popup
        // already comes from hyprctl, so this file does not work anywhere
        // else as it stands.
        HyprlandFocusGrab {
            windows: [win]
            active: true
            onCleared: Qt.quit()
        }
    }
}
