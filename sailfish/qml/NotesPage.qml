/* Copyright (C) 2017-2021 Michal Kosciesza <michal@mkiol.net>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

import harbour.dsnote.Settings 1.0
import harbour.dsnote.Dsnote 1.0

Page {
    id: root

    readonly property bool configured: app.available_langs.length > 0 && !app.busy
    readonly property bool inactive: app.intermediate_text.length === 0

    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height - panel.height

        contentHeight: Math.max(column.height + textArea.height, height)
        onContentHeightChanged: scrollToBottom()
        clip: true

        Column {
            id: column

            width: root.width
            spacing: Theme.paddingLarge

            PullDownMenu {
                busy: app.busy || app.audio_source_type === Dsnote.SourceFile

                MenuItem {
                    text: qsTr("About %1").arg(APP_NAME)
                    onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                }

                MenuItem {
                    text: qsTr("Settings")
                    onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }

                MenuItem {
                    enabled: configured
                    text: app.audio_source_type === Dsnote.SourceFile ? qsTr("Cancel file transcription") : qsTr("Transcribe audio file")
                    onClicked: {
                        if (app.audio_source_type === Dsnote.SourceFile)
                            app.cancel_file_source()
                        else
                            pageStack.push(fileDialog)
                    }
                }

                MenuItem {
                    visible: configured && app.audio_source_type === Dsnote.SourceNone
                    text: qsTr("Connect microphone")
                    onClicked: app.set_mic_source()
                }

                MenuItem {
                    enabled: textArea.text.length > 0
                    text: qsTr("Clear")
                    onClicked: _settings.note = ""
                }

                MenuItem {
                    visible: textArea.text.length > 0
                    text: qsTr("Copy")
                    onClicked: Clipboard.text = textArea.text
                }
            }
        }

        TextArea {
            id: textArea
            width: root.width
            opacity: configured ? 1.0 : 0.3
            Behavior on opacity { NumberAnimation { duration: 150 } }
            anchors.bottom: parent.bottom
            text: _settings.note
            verticalAlignment: TextEdit.AlignBottom
            background: null
            labelComponent: null
            onTextChanged: _settings.note = text

            Connections {
                target: app
                onText_changed: {
                    flick.scrollToBottom()
                }
            }
        }

        ViewPlaceholder {
            enabled: !configured && !app.busy
            text: qsTr("Language is not configured")
            hintText: qsTr("Pull down and select Settings to download language")
        }
    }

    VerticalScrollDecorator {
        flickable: flick
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: app.busy
        size: BusyIndicatorSize.Large
    }

    SilicaItem {
        id: panel
        visible: opacity > 0.0
        opacity: configured ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: intermediateLabel.height + 2 * Theme.paddingLarge
        highlighted: mouse.pressed

        property color pColor: _settings.speech_mode === Settings.SpeechAutomatic || app.audio_source_type !== Dsnote.SourceMic || highlighted ? Theme.highlightColor : Theme.primaryColor
        property color sColor: _settings.speech_mode === Settings.SpeechAutomatic || app.audio_source_type !== Dsnote.SourceMic || highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 1.0; color: Theme.rgba(root.palette.highlightBackgroundColor, 0.05) }
                GradientStop { position: 0.0; color: Theme.rgba(root.palette.highlightBackgroundColor, 0.10) }
            }
        }

        SpeechIndicator {
            id: indicator
            anchors.topMargin: Theme.paddingLarge
            anchors.top: parent.top
            anchors.leftMargin: Theme.paddingSmall
            anchors.left: parent.left
            width: Theme.itemSizeSmall
            color: panel.pColor
            active: app.speech
            off: app.audio_source_type === Dsnote.SourceNone
            Component.onCompleted: {
                height = parent.height / 2
            }

            visible: opacity > 0.0
            opacity: app.audio_source_type === Dsnote.SourceFile ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        BusyIndicator {
            id: busyIndicator
            size: BusyIndicatorSize.Medium
            anchors.centerIn: indicator
            running: app.audio_source_type === Dsnote.SourceFile

            Label {
                visible: app.progress > -1
                color: Theme.highlightColor
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeTiny
                text:  Math.round(app.progress * 100) + "%"
            }
        }

        Label {
            id: intermediateLabel
            anchors.topMargin: Theme.paddingLarge
            anchors.top: parent.top
            anchors.left: indicator.right
            anchors.right: parent.right
            anchors.rightMargin: Theme.horizontalPageMargin
            anchors.leftMargin: Theme.paddingMedium * 0.7
            text: inactive ?
                      app.audio_source_type === Dsnote.SourceFile ? qsTr("Transcribing audio file...") :
                      app.audio_source_type === Dsnote.SourceMic ?
                        _settings.speech_mode === Settings.SpeechAutomatic || app.speech ?
                        qsTr("Say something...") : qsTr("Press and say something...") :
                      "" : app.intermediate_text
            wrapMode: inactive ? Text.NoWrap : Text.WordWrap
            truncationMode: inactive ? TruncationMode.Fade : TruncationMode.None
            color: inactive ? panel.sColor : panel.pColor
            font.italic: inactive
        }

        MouseArea {
            id: mouse
            enabled: configured && _settings.speech_mode === Settings.SpeechManual &&
                     app.audio_source_type === Dsnote.SourceMic
            anchors.fill: parent

            onPressed: app.speech = true
            onReleased: app.speech = false
        }
    }

    Component {
        id: fileDialog
        FilePickerPage {
            nameFilters: [ '*.wav', '*.mp3', '*.ogg', '*.flac', '*.m4a', '*.aac', '*.opus' ]
            onSelectedContentPropertiesChanged: {
                app.set_file_source(selectedContentProperties.filePath)
            }
        }
    }

    Toast {
        id: notification
    }

    Connections {
        target: app

        onError: {
            switch (type) {
            case Dsnote.ErrorFileSource:
                notification.show(qsTr("Audio file couldn't be transcribed."))
                break;
            case Dsnote.ErrorMicSource:
                notification.show(qsTr("Microphone was unexpectedly disconnected."))
                break;
            default:
                notification.show(qsTr("Oops! Something went wrong."))
            }
        }

        onTranscribe_done: notification.show(qsTr("Audio file transcription is completed."))
    }
}
