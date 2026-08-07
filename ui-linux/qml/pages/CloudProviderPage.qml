import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Page {
    title: "Fournisseur de cloud"

    property var providers: [
        { value: "local", name: "Stockage local", desc: "Sauvegardes stockées dans le répertoire Steam uniquement. Pas de synchronisation cloud." },
        { value: "folder", name: "Dossier personnalisé", desc: "Synchronisez avec un partage réseau ou un autre chemin local." },
        { value: "gdrive", name: "Google Drive", desc: "Synchronisez les enregistrements sur votre compte Google Drive." },
        { value: "onedrive", name: "OneDrive", desc: "Synchronisez les enregistrements sur votre compte Microsoft OneDrive." },
        { value: "r2", name: "Cloudflare R2", desc: "Synchronisez les enregistrements dans un compartiment Cloudflare R2 (S3-compatible)." },
        { value: "s3", name: "Compatible S3", desc: "Synchronisez les enregistrements sur n'importe quel service S3-compatible (AWS S3, MinIO, Backblaze B2, Wasabi, self-hosted)." }
    ]

    property bool comboReady: false

    // True while a credential save + connection test is in flight (disables Save).
    property bool saving: false
    
    // Track auth state locally so bindings update when settingsChanged fires
    property bool gdriveAuth: backend ? backend.isProviderAuthenticated("gdrive") : false
    property bool onedriveAuth: backend ? backend.isProviderAuthenticated("onedrive") : false
    property bool r2Auth: backend ? backend.isProviderAuthenticated("r2") : false
    property bool s3Auth: backend ? backend.isProviderAuthenticated("s3") : false
    
    function refreshAuthState() {
        gdriveAuth = backend ? backend.isProviderAuthenticated("gdrive") : false
        onedriveAuth = backend ? backend.isProviderAuthenticated("onedrive") : false
        r2Auth = backend ? backend.isProviderAuthenticated("r2") : false
        s3Auth = backend ? backend.isProviderAuthenticated("s3") : false
    }

    // Pre-fill the R2 form from the saved credentials (non-secret fields only).
    function loadR2Form() {
        if (!backend) return
        var c = backend.getR2Credentials()
        r2AccountIdField.text = c.account_id || ""
        r2AccessKeyField.text = c.access_key_id || ""
        r2BucketField.text = c.bucket || ""
        r2KeyPrefixField.text = c.key_prefix || ""
        r2EndpointField.text = c.endpoint || ""
        // Leave the secret blank; show a hint that one is already stored.
        r2SecretField.text = ""
        r2HasSecret = c.has_secret === true
    }

    property bool r2HasSecret: false

    // Pre-fill the S3 form from the saved credentials (non-secret fields only).
    function loadS3Form() {
        if (!backend) return
        var c = backend.getS3Credentials()
        s3AccessKeyField.text = c.access_key_id || ""
        s3BucketField.text = c.bucket || ""
        s3EndpointField.text = c.endpoint || ""
        s3RegionField.text = c.region || ""
        s3KeyPrefixField.text = c.key_prefix || ""
        s3SignPayloadCheck.checked = c.sign_payload === true
        s3InsecureHttpCheck.checked = c.allow_insecure_http === true
        s3InsecureTlsCheck.checked = c.allow_insecure_tls === true
        s3CaCertField.text = c.ca_cert_path || ""
        // Leave the secret blank; show a hint that one is already stored.
        s3SecretField.text = ""
        s3HasSecret = c.has_secret === true
    }

    property bool s3HasSecret: false

    function currentProviderIndex() {
        var name = (backend && backend.providerName) ? backend.providerName : "local"
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].value === name) return i
        }
        return 0
    }
    
    // Bounds-safe provider lookup
    function currentProvider() {
        var idx = providerCombo.currentIndex
        if (idx >= 0 && idx < providers.length) return providers[idx]
        return providers[0]  // fallback to local
    }

    FolderDialog {
        id: folderDialog
        title: "Sélectionnez le dossier de synchronisation"
        onAccepted: {
            // Convert file:// URL to path
            var path = selectedFolder.toString()
            if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            if (backend) backend.syncFolderPath = path
        }
    }

    Connections {
        target: oauth
        function onStatusMessage(msg) {
            statusText.text = msg
            authUrlBox.visible = false
        }
        function onAuthSucceeded(provider) {
            statusText.text = "Authentification réussie !"
            authUrlBox.visible = false
            backend.refreshStatus()
            refreshAuthState()
        }
        function onAuthFailed(provider, error) {
            statusText.text = "Erreur:" + error
            authUrlBox.visible = false
        }
        function onBrowserFailed(url) {
            statusText.text = "Impossible d'ouvrir le navigateur. Copiez l'URL ci-dessous et collez-la dans votre navigateur :"
            authUrlField.text = url
            authUrlBox.visible = true
        }
    }
    
    Connections {
        target: backend
        function onSettingsChanged() {
            refreshAuthState()
            // Keep combo in sync with backend
            if (comboReady) {
                var expected = currentProviderIndex()
                if (providerCombo.currentIndex !== expected)
                    providerCombo.currentIndex = expected
            }
        }
        // Result of the on-save connection test for R2/S3.
        function onProviderTestFinished(provider, ok, error) {
            saving = false
            if (ok) {
                statusText.text = "Connecté. Identifiants enregistrés."
                backend.saveConfig()
                refreshAuthState()
                if (provider === "s3") loadS3Form()
                else if (provider === "r2") loadR2Form()
            } else {
                statusText.text = "Erreur:" + error
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
                text: "Fournisseur de cloud"
                font.pointSize: 16
                font.bold: true
                Layout.leftMargin: 20
            }

            Label {
                text: "Choisissez où CloudRedirect synchronise vos fichiers de sauvegarde."
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
                    width: parent.width
                    spacing: 8

                    Label {
                        text: "Fournisseur"
                        font.bold: true
                    }

                    ComboBox {
                        id: providerCombo
                        Layout.fillWidth: true
                        model: providers.map(p => p.name)
                        Component.onCompleted: {
                            comboReady = true
                            currentIndex = currentProviderIndex()
                        }
                        onCurrentIndexChanged: {
                            if (comboReady && currentIndex >= 0 && backend) {
                                backend.providerName = providers[currentIndex].value
                            }
                        }
                    }

                    Label {
                        text: currentProvider().desc
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                visible: currentProvider().value !== "local"

                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    Label {
                        text: "Statut"
                        font.bold: true
                    }
                    Label {
                        text: {
                            var provider = currentProvider()
                            if (provider.value === "folder") {
                                if (backend && backend.syncFolderPath)
                                    return "Synchronisation avec" + backend.syncFolderPath
                                return "Aucun dossier configuré"
                            }
                            if (provider.value === "gdrive" && gdriveAuth) return "Authentifié"
                            if (provider.value === "onedrive" && onedriveAuth) return "Authentifié"
                            if (provider.value === "r2") return r2Auth ? "Identifiants enregistrés" : "Aucune information d'identification enregistrée"
                            if (provider.value === "s3") return s3Auth ? "Identifiants enregistrés" : "Aucune information d'identification enregistrée"
                            return "Non authentifié"
                        }
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Frame {
                visible: currentProvider().value === "folder"
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    Label {
                        text: "Dossier de synchronisation"
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: folderPathField
                            Layout.fillWidth: true
                            placeholderText: "/path/to/sync/folder"
                            text: backend ? backend.syncFolderPath : ""
                            onEditingFinished: { if (backend) backend.syncFolderPath = text }
                        }

                        Button {
                            text: "Parcourir..."
                            onClicked: folderDialog.open()
                        }
                    }

                    Label {
                        text: "Choisissez un dossier sur un partage réseau, un lecteur externe ou un répertoire cloud-synced (par exemple, Dropbox, Syncthing)."
                        opacity: 0.6
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        font.pointSize: 9
                    }
                }
            }

            Frame {
                id: r2Frame
                visible: currentProvider().value === "r2"
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                // Populate the fields whenever this panel becomes visible.
                onVisibleChanged: if (visible) loadR2Form()

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: "Informations d'identification Cloudflare R2"
                        font.bold: true
                    }
                    Label {
                        text: "Créez un bucket R2 sur votre tableau de bord Cloudflare. Générez des jetons, saisissez-les ici."
                            + "Les informations d'identification saisies ici sont stockées dans r2_credentials.json"
                        opacity: 0.6
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Identifiant du compte"; opacity: 0.8 }
                        TextField {
                            id: r2AccountIdField
                            Layout.fillWidth: true
                            placeholderText: "par ex. 1a2b3c4d5e6f..."
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "ID de clé d'accès"; opacity: 0.8 }
                        TextField {
                            id: r2AccessKeyField
                            Layout.fillWidth: true
                            placeholderText: "Identifiant de la clé d'accès R2"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Clé d'accès secrète"; opacity: 0.8 }
                        TextField {
                            id: r2SecretField
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: r2HasSecret
                                ? "(inchangé - laisser vide pour conserver l'existant)"
                                : "Clé d'accès secrète R2"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Seau"; opacity: 0.8 }
                        TextField {
                            id: r2BucketField
                            Layout.fillWidth: true
                            placeholderText: "nom du compartiment"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Préfixe de clé (facultatif)"; opacity: 0.8 }
                        TextField {
                            id: r2KeyPrefixField
                            Layout.fillWidth: true
                            placeholderText: "par ex. redirection vers le cloud/"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Point de terminaison (facultatif)"; opacity: 0.8 }
                        TextField {
                            id: r2EndpointField
                            Layout.fillWidth: true
                            placeholderText: "laisser vide pour <account>.r2.cloudflarestorage.com"
                        }
                    }

                }
            }

            Frame {
                id: s3Frame
                visible: currentProvider().value === "s3"
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                // Populate the fields whenever this panel becomes visible.
                onVisibleChanged: if (visible) loadS3Form()

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: "Informations d'identification compatibles S3"
                        font.bold: true
                    }
                    Label {
                        text: "Ajoutez votre fournisseur compatible S3"
                        opacity: 0.6
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Point de terminaison"; opacity: 0.8 }
                        TextField {
                            id: s3EndpointField
                            Layout.fillWidth: true
                            placeholderText: "par ex. s3.us-east-1.amazonaws.com ou minio.example.com:9000"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "ID de clé d'accès"; opacity: 0.8 }
                        TextField {
                            id: s3AccessKeyField
                            Layout.fillWidth: true
                            placeholderText: "identifiant de clé d'accès"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Clé d'accès secrète"; opacity: 0.8 }
                        TextField {
                            id: s3SecretField
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: s3HasSecret
                                ? "(inchangé - laisser vide pour conserver l'existant)"
                                : "clé d'accès secrète"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Seau"; opacity: 0.8 }
                        TextField {
                            id: s3BucketField
                            Layout.fillWidth: true
                            placeholderText: "nom du compartiment"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Région"; opacity: 0.8 }
                        TextField {
                            id: s3RegionField
                            Layout.fillWidth: true
                            placeholderText: "par ex. nous-east-1"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Préfixe de clé (facultatif)"; opacity: 0.8 }
                        TextField {
                            id: s3KeyPrefixField
                            Layout.fillWidth: true
                            placeholderText: "par ex. redirection vers le cloud/"
                        }
                    }

                    // ── Advanced: transport + signing options for self-hosted servers ──
                    Label {
                        text: "Avancé"
                        font.bold: true
                        Layout.topMargin: 4
                    }

                    CheckBox {
                        id: s3SignPayloadCheck
                        text: "Signer les charges utiles de la demande (hachage de corps SHA-256)"
                    }
                    CheckBox {
                        id: s3InsecureHttpCheck
                        text: "Autoriser les points de terminaison HTTP simples (non sécurisés)"
                    }
                    CheckBox {
                        id: s3InsecureTlsCheck
                        text: "Ignorer la vérification du certificat TLS (non sécurisé)"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: "Chemin du certificat CA (facultatif)"; opacity: 0.8 }
                        TextField {
                            id: s3CaCertField
                            Layout.fillWidth: true
                            placeholderText: "par ex. /path/to/ca.pem pour un serveur self-signed"
                        }
                    }

                }
            }

            Button {
                visible: currentProvider().value === "gdrive"
                Layout.leftMargin: 20
                text: gdriveAuth ? "Re-authenticate" : "Connectez-vous avec Google"
                highlighted: !gdriveAuth
                onClicked: {
                    if (backend && oauth) {
                        let tokenPath = backend.providerPath || backend.defaultTokenPath("gdrive")
                        oauth.startAuth("gdrive", tokenPath)
                    }
                }
            }

            Button {
                visible: currentProvider().value === "onedrive"
                Layout.leftMargin: 20
                text: onedriveAuth ? "Re-authenticate" : "Connectez-vous avec Microsoft"
                highlighted: !onedriveAuth
                onClicked: {
                    if (backend && oauth) {
                        let tokenPath = backend.providerPath || backend.defaultTokenPath("onedrive")
                        oauth.startAuth("onedrive", tokenPath)
                    }
                }
            }

            Label {
                id: statusText
                text: ""
                visible: text !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                opacity: 0.7
            }

            RowLayout {
                id: authUrlBox
                visible: false
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 8

                TextField {
                    id: authUrlField
                    readOnly: true
                    selectByMouse: true
                    Layout.fillWidth: true
                    font.pointSize: 8
                }

                Button {
                    text: "Copie"
                    onClicked: {
                        authUrlField.selectAll()
                        authUrlField.copy()
                        authUrlField.deselect()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 12

                Label {
                    text: "Les modifications prendront effet au prochain lancement de Steam."
                    opacity: 0.6
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: saving ? "Test de connexion..." : "Sauvegarder"
                    highlighted: true
                    enabled: !saving
                    onClicked: {
                        if (!backend) return
                        var p = currentProvider().value

                        if (p === "s3") {
                            var okS3 = backend.saveS3Credentials(
                                s3AccessKeyField.text,
                                s3SecretField.text,
                                s3BucketField.text,
                                s3EndpointField.text,
                                s3RegionField.text,
                                s3KeyPrefixField.text,
                                s3SignPayloadCheck.checked,
                                s3InsecureHttpCheck.checked,
                                s3InsecureTlsCheck.checked,
                                s3CaCertField.text)
                            if (!okS3) {
                                statusText.text = "Erreur : ID de clé d'accès, clé d'accès secrète,"
                                    + "Le bucket, le point de terminaison et la région sont requis."
                                return
                            }
                            // Verify the endpoint actually works before committing.
                            statusText.text = "Test de connexion..."
                            saving = true
                            backend.testProviderConnection("s3")
                            return
                        }

                        if (p === "r2") {
                            var okR2 = backend.saveR2Credentials(
                                r2AccountIdField.text,
                                r2AccessKeyField.text,
                                r2SecretField.text,
                                r2BucketField.text,
                                r2KeyPrefixField.text,
                                r2EndpointField.text)
                            if (!okR2) {
                                statusText.text = "Erreur : ID de compte, ID de clé d'accès,"
                                    + "Le bucket et la clé d'accès secrète sont requis."
                                return
                            }
                            statusText.text = "Test de connexion..."
                            saving = true
                            backend.testProviderConnection("r2")
                            return
                        }

                        // Non-credential providers just persist config.
                        backend.saveConfig()
                        statusText.text = "Enregistré."
                    }
                }
            }
        }
    }
}
