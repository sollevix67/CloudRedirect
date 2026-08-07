import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Applications"

    property var appsList: []
    property var filteredLocalApps: []
    property var filteredRemoteApps: []
    property string searchText: ""
    property string statusText: ""

    Component.onCompleted: {
        reloadApps()
        if (backend) backend.fetchRemoteApps()
    }

    function reloadApps() {
        appsList = backend ? backend.getAppDetails() : []
        updateFilteredLists()
    }

    function updateFilteredLists() {
        var localCount = 0
        var remoteCount = 0
        var localResult = []
        var remoteResult = []
        var needle = searchText.toLowerCase()

        for (var i = 0; i < appsList.length; i++) {
            var app = appsList[i]
            var matches = (needle === "") ||
                          String(app.appId).indexOf(needle) >= 0 ||
                          app.name.toLowerCase().indexOf(needle) >= 0

            if (app.isLocal) {
                localCount++
                if (matches) localResult.push(app)
            }
            if (app.isRemote && !app.isLocal) {
                remoteCount++
                if (matches) remoteResult.push(app)
            }
        }

        localResult.sort(function(a, b) { return a.appId - b.appId })
        remoteResult.sort(function(a, b) { return a.appId - b.appId })

        filteredLocalApps = localResult
        filteredRemoteApps = remoteResult
        statusText = localCount + "locale," + remoteCount + "télécommande"
    }

    onSearchTextChanged: updateFilteredLists()

    function formatProviderName(name) {
        if (backend) return backend.providerLabel(name)
        return name
    }

    Connections {
        target: backend
        function onAppNamesResolved() {
            reloadApps()
        }
        function onAppsChanged() {
            reloadApps()
        }
        function onRemoteAppsFetched() {
            reloadApps()
        }
    }

    Dialog {
        id: deleteDialog
        title: "Supprimer les données de l'application"
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 480)

        property var targetApp: null
        property int countdown: 5
        property bool canDelete: false

        Timer {
            id: countdownTimer
            interval: 1000
            repeat: true
            onTriggered: {
                deleteDialog.countdown--
                if (deleteDialog.countdown <= 0) {
                    countdownTimer.stop()
                    deleteDialog.canDelete = true
                }
            }
        }

        onOpened: {
            countdown = 5
            canDelete = false
            countdownTimer.start()
        }

        onClosed: {
            countdownTimer.stop()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Supprimer toutes les sauvegardes pour '" + (deleteDialog.targetApp ? deleteDialog.targetApp.name : "") + "' (" + (deleteDialog.targetApp ? deleteDialog.targetApp.appId : "") + ")"
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "Cela supprimera définitivement :"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                spacing: 2
                Layout.leftMargin: 12

                Label {
                    text: "• " + (deleteDialog.targetApp ? deleteDialog.targetApp.fileCount : "") + "fichier(s) (" + (deleteDialog.targetApp ? deleteDialog.targetApp.sizeFormatted : "") + ") à partir du stockage CloudRedirect local"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    opacity: 0.8
                }

                Label {
                    text: "• Répertoire de données utilisateur Steam pour cette application"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    opacity: 0.8
                }
            }

            Label {
                text: {
                    var provider = backend ? backend.providerName : "local"
                    if (provider === "gdrive" || provider === "onedrive" || provider === "r2")
                        return "La copie cloud dans" + formatProviderName(provider) + "sera également supprimé."
                    return ""
                }
                visible: text !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                opacity: 0.7
            }

            Label {
                text: "Les données seront re-downloaded depuis le cloud lors du prochain lancement du jeu. Une sauvegarde sera créée avant la suppression."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                opacity: 0.7
            }

            Label {
                text: "Cela ne peut pas être annulé."
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Item { Layout.fillWidth: true }

                Button {
                    text: "Annuler"
                    onClicked: deleteDialog.close()
                }

                Button {
                    text: deleteDialog.canDelete ? "Supprimer toutes les sauvegardes" : "Supprimer (" + deleteDialog.countdown + ")"
                    enabled: deleteDialog.canDelete
                    onClicked: {
                        if (backend && deleteDialog.targetApp) {
                            backend.deleteAppData(deleteDialog.targetApp.appId)
                        }
                        deleteDialog.close()
                        reloadApps()
                    }
                }
            }
        }
    }

    // Orphan results dialog
    Dialog {
        id: orphanDialog
        title: "Résultats de l'analyse orpheline"
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 480)

        property var results: []

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Label {
                text: orphanDialog.results.length === 0
                      ? "Aucun blobs orphelin trouvé. Le stockage est propre."
                      : orphanDialog.results.length + "application(s) avec des blobs orphelins :"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Repeater {
                model: orphanDialog.results

                Frame {
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2

                        Label {
                            text: modelData.name + " (" + modelData.appId + ")"
                            font.bold: true
                        }
                        Label {
                            text: modelData.orphanCount + "fichier(s) orphelin(s)," + modelData.orphanSizeFormatted
                            opacity: 0.7
                        }
                    }
                }
            }
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
                text: "Applications"
                font.pointSize: 16
                font.bold: true
                Layout.leftMargin: 20
            }

            Label {
                text: "Sauvegardes cloud gérées par CloudRedirect. Recherchez par nom ou ID d'application."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 8

                TextField {
                    id: searchField
                    placeholderText: "Rechercher par nom ou ID d'application..."
                    Layout.fillWidth: true
                    onTextChanged: searchText = text
                }

                Button {
                    text: "Scanner les orphelins"
                    onClicked: {
                        var results = backend ? backend.scanOrphans() : []
                        orphanDialog.results = results
                        orphanDialog.open()
                    }
                }

                Button {
                    text: "Rafraîchir"
                    onClicked: {
                        if (backend) {
                            backend.refreshStatus()
                            backend.fetchRemoteApps()
                        }
                        reloadApps()
                    }
                }
            }

            // Local Saves section
            Label {
                text: "Sauvegardes locales"
                font.pointSize: 13
                font.bold: true
                Layout.leftMargin: 20
                Layout.topMargin: 8
            }

            Repeater {
                model: filteredLocalApps

                Frame {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Image {
                            source: modelData.headerUrl
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 56
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0.5, 0.5, 0.5, 0.15)
                                visible: parent.status !== Image.Ready
                                radius: 2

                                Label {
                                    anchors.centerIn: parent
                                    text: String(modelData.appId)
                                    opacity: 0.4
                                    font.pointSize: 9
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 450
                            spacing: 4
                            Label {
                                text: modelData.name
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: "IDENTIFIANT:" + modelData.appId + "  •  " + modelData.fileCount + "fichier(s) •" + modelData.sizeFormatted + (modelData.saveRoot ? "  •  " + modelData.saveRoot : "")
                                opacity: 0.7
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            icon.name: "edit-delete"
                            text: "Supprimer"
                            display: AbstractButton.TextBesideIcon
                            onClicked: {
                                deleteDialog.targetApp = modelData
                                deleteDialog.open()
                            }
                        }
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: filteredLocalApps.length === 0 && searchText === ""
                text: "Aucune sauvegarde locale trouvée."
                opacity: 0.5
            }

            Label {
                text: "Sauvegardes à distance"
                font.pointSize: 13
                font.bold: true
                Layout.leftMargin: 20
                Layout.topMargin: 8
                visible: filteredRemoteApps.length > 0
            }

            Label {
                text: "Applications avec sauvegarde des données dans le stockage cloud qui ne sont pas téléchargées localement."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: 0.7
                visible: filteredRemoteApps.length > 0
            }

            Repeater {
                model: filteredRemoteApps

                Frame {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Image {
                            source: modelData.headerUrl
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 56
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0.5, 0.5, 0.5, 0.15)
                                visible: parent.status !== Image.Ready
                                radius: 2

                                Label {
                                    anchors.centerIn: parent
                                    text: String(modelData.appId)
                                    opacity: 0.4
                                    font.pointSize: 9
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 450
                            spacing: 4
                            Label {
                                text: modelData.name
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: "IDENTIFIANT:" + modelData.appId + "•  Compte:" + (backend ? backend.accountName : "Unknown")
                                opacity: 0.7
                            }
                            Label {
                                text: "Non téléchargé localement • Sera téléchargé au prochain lancement du jeu"
                                opacity: 0.5
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: filteredRemoteApps.length === 0 && searchText === ""
                text: "Aucune sauvegarde remote-only trouvée."
                opacity: 0.5
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                visible: appsList.length === 0
                text: "Aucune application trouvée.\n\nInstallez les jeux via SLSsteam pour les voir ici."
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.5
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                visible: appsList.length > 0 && filteredLocalApps.length === 0 && filteredRemoteApps.length === 0 && searchText !== ""
                text: "Aucune application ne correspond à \\\"" + searchText + "\""
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.5
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                Label {
                    text: statusText
                    opacity: 0.6
                }
                Item { Layout.fillWidth: true }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
