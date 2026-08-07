import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Installation"

    Dialog {
        id: purgeDialog
        title: "Supprimer toutes les données"
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 480)

        property int countdown: 5
        property bool canPurge: false

        Timer {
            id: purgeCountdownTimer
            interval: 1000
            repeat: true
            onTriggered: {
                purgeDialog.countdown--
                if (purgeDialog.countdown <= 0) {
                    purgeCountdownTimer.stop()
                    purgeDialog.canPurge = true
                }
            }
        }

        onOpened: {
            countdown = 5
            canPurge = false
            purgeCountdownTimer.start()
        }

        onClosed: {
            purgeCountdownTimer.stop()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Cela supprimera définitivement :"
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                spacing: 2
                Layout.leftMargin: 12

                Label { text: "• CloudRedirect depuis Steam (hook LD_AUDIT)"; opacity: 0.8; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Label { text: "• cloud_redirect.so et binaire CLI"; opacity: 0.8; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Label { text: "• Toute la configuration et les paramètres"; opacity: 0.8; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Label { text: "• Jetons OAuth (Google Drive/OneDrive)"; opacity: 0.8; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Label { text: "• Toutes les sauvegardes mises en cache et les données cloud"; opacity: 0.8; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Label { text: "• Journaux et sauvegardes"; opacity: 0.8; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }

            Label {
                text: "Cela ne peut pas être annulé. Vous devrez re-authenticate et re-deploy pour utiliser à nouveau CloudRedirect."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Item { Layout.fillWidth: true }

                Button {
                    text: "Annuler"
                    onClicked: purgeDialog.close()
                }

                Button {
                    text: purgeDialog.canPurge ? "Supprimer toutes les données" : "Retirer (" + purgeDialog.countdown + ")"
                    enabled: purgeDialog.canPurge
                    onClicked: {
                        if (deployer) deployer.purgeAll()
                        purgeDialog.close()
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
                text: "Installation"
                font.pointSize: 16
                font.bold: true
                Layout.leftMargin: 20
            }

            Label {
                text: "v" + (backend ? backend.version : "")
                Layout.leftMargin: 20
                opacity: 0.7
            }

            Label {
                text: "Déployez ou supprimez CloudRedirect."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: 0.7
            }

            // SLSsteam status
            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    width: parent.width
                    spacing: 4

                    Label {
                        text: "SLSsteam"
                        font.bold: true
                    }
                    Label {
                        text: deployer && deployer.slssteamInstalled ? "Installé" : "Pas trouvé"
                        opacity: 0.7
                    }
                    Label {
                        visible: deployer && deployer.slssteamInstalled && deployer.slsCloudBlocked
                        text: "La sauvegarde dans le cloud est désactivée dans votre configuration SLSsteam !"
                        color: "#e74c3c"
                    }
                    Label {
                        visible: deployer && deployer.slssteamInstalled && deployer.slsCloudBlocked
                        text: "Définir DisableCloud : non dans ~/.config/SLSsteam/config.yaml"
                        font.family: "monospace"
                        opacity: 0.6
                    }
                }
            }

            // CloudRedirect status
            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    width: parent.width
                    spacing: 4

                    Label {
                        text: "CloudRedirect"
                        font.bold: true
                    }
                    Label {
                        text: {
                            if (!deployer) return "Unknown"
                            if (!deployer.alreadyDeployed) return "Non déployé"
                            if (deployer.updateAvailable) return "Mise à jour disponible"
                            return "Déployé, à jour"
                        }
                        opacity: 0.7
                    }
                    Label {
                        visible: deployer && deployer.updateAvailable && deployer.deployedVersion && deployer.bundledVersion
                        text: deployer ? (deployer.deployedVersion + " → " + deployer.bundledVersion) : ""
                        font.family: "monospace"
                        opacity: 0.6
                    }
                }
            }

            // Status message
            Label {
                text: deployer ? deployer.statusMessage : ""
                visible: deployer && deployer.statusMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: 0.7
            }

            // Action buttons
            RowLayout {
                Layout.leftMargin: 20
                spacing: 8

                Button {
                    text: "Déployer"
                    enabled: deployer && deployer.slssteamInstalled && !deployer.alreadyDeployed
                    highlighted: deployer && deployer.slssteamInstalled && !deployer.alreadyDeployed
                    onClicked: { if (deployer) deployer.deploy() }
                }

                Button {
                    text: "Mise à jour"
                    visible: deployer && deployer.updateAvailable
                    highlighted: true
                    onClicked: { if (deployer) deployer.update() }
                }

                Button {
                    text: "Retirer"
                    enabled: deployer && deployer.alreadyDeployed
                    onClicked: { if (deployer) deployer.undeploy() }
                }

                Button {
                    text: "Supprimer toutes les données"
                    onClicked: purgeDialog.open()
                }

                Button {
                    text: "Rafraîchir"
                    onClicked: { if (deployer) deployer.checkPrerequisites() }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
