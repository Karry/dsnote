/* Copyright (C) 2021 Michal Kosciesza <michal@mkiol.net>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Page {
    id: root

    title: qsTr("Languages")

    // app.langs:
    // [0] - model id
    // [1] - lang id
    // [2] - friendly name
    // [3] - model availability
    // [4] - download in progress
    // [5] - download progress

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.height + 20
        clip: true

        ScrollIndicator.vertical: ScrollIndicator {}

        GridLayout {
            id: content
            x: 10
            y: 10
            width: parent.width - 20
            flow: GridLayout.TopToBottom
            columnSpacing: 10
            rowSpacing: 10
            columns: 3
            rows: app.langs.length

            Repeater {
                model: app.langs
                Label {
                    text: modelData[2]
                }
            }

            Repeater {
                model: app.langs
                ProgressBar {
                    id: bar
                    Layout.fillWidth: true
                    value: modelData[3] ? 1 : modelData[5]

                    Connections {
                        target: app
                        function onLang_download_progress(id, progress) {
                            if (modelData[0] === id) {
                                bar.value = progress
                            }
                        }
                    }
                }
            }

            Repeater {
                model: app.langs
                Button {
                    enabled: !modelData[4]
                    text: modelData[4] ? qsTr("Downloading...") : modelData[3] ? qsTr("Delete") : qsTr("Download")
                    onClicked: {
                        if (modelData[3])
                            app.delete_lang(modelData[0])
                        else
                            app.download_lang(modelData[0])
                    }
                }
            }
        }
    }
}
