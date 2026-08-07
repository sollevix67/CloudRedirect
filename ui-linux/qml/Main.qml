import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "pages"

ApplicationWindow {
    id: root
    width: 720
    height: 620
    minimumWidth: 600
    minimumHeight: 500
    title: "CloudRedirect"
    visible: true

    // Navigate to Setup tab after deploy/undeploy actions if needed
    Connections {
        target: deployer
        function onCheckCompleted() {
            if (deployer && (!deployer.alreadyDeployed || deployer.updateAvailable)) {
                tabBar.currentIndex = 4  // Setup tab
            }
        }
    }

    // Auto-update prompt on first launch + initial setup navigation
    Component.onCompleted: {
        if (deployer && (!deployer.alreadyDeployed || deployer.updateAvailable)) {
            tabBar.currentIndex = 4
        }
        if (backend && backend.shouldOfferAutoUpdates()) {
            autoUpdateDialog.open()
        } else if (backend) {
            backend.checkForFlatpakUpdate()
        }
    }

    Connections {
        target: backend
        function onFlatpakUpdateAvailable() {
            updateAvailableDialog.open()
        }
        function onFlatpakUpdateCompleted(success) {
            if (success) {
                restartDialog.open()
            }
        }
    }

    Dialog {
        id: updateAvailableDialog
        title: "Mise à jour disponible"
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 440)

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Une nouvelle version de CloudRedirect est disponible."
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "Mettez à jour maintenant pour obtenir les dernières fonctionnalités et correctifs."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Item { Layout.fillWidth: true }

                Button {
                    text: "Plus tard"
                    onClicked: updateAvailableDialog.close()
                }

                Button {
                    text: "Mettre à jour maintenant"
                    highlighted: true
                    onClicked: {
                        if (backend) backend.applyFlatpakUpdate()
                        updateAvailableDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: restartDialog
        title: "Redémarrage requis"
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 440)

        Label {
            text: "CloudRedirect a été mis à jour. Veuillez redémarrer l'application pour utiliser la nouvelle version."
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    Dialog {
        id: autoUpdateDialog
        title: "Activer les mises à jour automatiques"
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 440)

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Souhaitez-vous recevoir des mises à jour automatiques ?"
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "CloudRedirect peut ajouter son référentiel de mise à jour afin que les nouvelles versions soient installées automatiquement via Flatpak. Vous pourrez le supprimer plus tard depuis les paramètres."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Item { Layout.fillWidth: true }

                Button {
                    text: "Pas maintenant"
                    onClicked: {
                        if (backend) backend.dismissAutoUpdatePrompt()
                        autoUpdateDialog.close()
                    }
                }

                Button {
                    text: "Activer les mises à jour"
                    highlighted: true
                    onClicked: {
                        if (backend) backend.enableAutoUpdates()
                        autoUpdateDialog.close()
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            // Size each tab to its label so wider labels aren't truncated.
            TabButton { text: "Tableau de bord";      width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
            TabButton { text: "Applications";           width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
            TabButton { text: "Sauvegardes";        width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
            TabButton { text: "Fournisseur de cloud"; width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
            TabButton { text: "Installation";          width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
            TabButton { text: "Synchronisation des statistiques";     width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
            TabButton { text: "Migration";      width: Math.max(implicitWidth, contentItem.implicitWidth + 24) }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            DashboardPage {}
            AppsPage {}
            BackupsPage {}
            CloudProviderPage {}
            SetupPage {}
            StatsPage {}
            MigrationPage {}
        }
    }
}
