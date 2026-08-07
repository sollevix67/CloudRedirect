import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Tableau de bord"
    
    // Track auth state locally so bindings update
    property bool providerAuth: backend ? backend.providerAuthenticated : false

    function formatProviderName(name) {
        if (backend) return backend.providerLabel(name)
        return name
    }
    
    function refreshState() {
        providerAuth = backend ? backend.providerAuthenticated : false
    }

    Component.onCompleted: {
        console.log("DashboardPage.onCompleted - appelant fetchRemoteApps")
        // Fetch remote apps when dashboard loads
        if (backend) backend.fetchRemoteApps()
    }
    
    Connections {
        target: backend
        function onSettingsChanged() {
            refreshState()
        }
        function onStatusChanged() {
            refreshState()
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 12

            Item { height: 8 }

            Label {
                text: "Tableau de bord"
                font.pointSize: 16
                font.bold: true
                Layout.leftMargin: 20
            }

            Label {
                text: "CloudRedirect v" + (backend ? backend.version : "")
                Layout.leftMargin: 20
                opacity: 0.7
            }

            Label {
                text: "Accueillir!"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: 0.7
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Label {
                        text: "Fournisseur de cloud"
                        font.bold: true
                    }
                    Label {
                        text: {
                            if (!backend || !backend.providerName || backend.providerName === "local")
                                return "Non configuré"
                            if (providerAuth)
                                return formatProviderName(backend.providerName) + "— Authentifié"
                            return formatProviderName(backend.providerName) + "— Non authentifié"
                        }
                        opacity: 0.7
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Label {
                        text: "Synchronisation des applications"
                        font.bold: true
                    }
                    Label {
                        text: {
                            var local = backend ? backend.managedAppCount : 0
                            var remoteOnly = backend ? backend.remoteOnlyAppCount : 0
                            if (remoteOnly > 0)
                                return local + "locale," + remoteOnly + "à distance uniquement"
                            return local + "application(s) avec données cloud"
                        }
                        opacity: 0.7
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Label {
                        text: "CloudRedirect"
                        font.bold: true
                    }
                    Label {
                        text: (backend && backend.deployed) ? "Installé" : "Non installé"
                        opacity: 0.7
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: "Notifications de lancement"
                            font.bold: true
                        }
                        Label {
                            text: "Afficher une notification sur le bureau lors du chargement de CloudRedirect"
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: backend ? backend.notificationsEnabled : true
                        onToggled: { if (backend) backend.notificationsEnabled = checked }
                    }
                }
            }

            RowLayout {
                Layout.leftMargin: 20
                spacing: 8

                Button {
                    text: "Ouvrir le fichier journal"
                    onClicked: { if (backend) backend.openLogFile() }
                }

                Button {
                    text: "Ouvrir le dossier de configuration"
                    onClicked: { if (backend) backend.openConfigFolder() }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
