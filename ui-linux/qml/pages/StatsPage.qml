import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Synchronisation des statistiques"

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 12

            Item { height: 8 }

            Label {
                text: "Synchronisation des statistiques"
                font.pointSize: 16
                font.bold: true
                Layout.leftMargin: 20
            }

            Label {
                text: "Fonctionnalités expérimentales ! Peut entraîner une perte de données et des problèmes étranges ! Vous êtes prévenu !"
                opacity: 0.7
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "Activer la synchronisation des statistiques"
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Switch {
                        checked: backend ? backend.statsSyncEnabled : true
                        onToggled: { if (backend) backend.statsSyncEnabled = checked }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: (backend && backend.statsSyncEnabled) ? 1.0 : 0.5

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "Réalisations de synchronisation"
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Switch {
                        checked: backend ? backend.syncAchievements : false
                        enabled: backend ? backend.statsSyncEnabled : false
                        onToggled: { if (backend) backend.syncAchievements = checked }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: (backend && backend.statsSyncEnabled) ? 1.0 : 0.5

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "Synchroniser la durée de lecture"
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Switch {
                        checked: backend ? backend.syncPlaytime : false
                        enabled: backend ? backend.statsSyncEnabled : false
                        onToggled: { if (backend) backend.syncPlaytime = checked }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
