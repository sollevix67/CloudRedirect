# CloudRedirect

« Steam Cloud » pour les jeux « lua ».

**Ceci est l’unique source officielle de CloudRedirect. Aucun autre site web n’est exploité par l’auteur ni approuvé par ce projet. Au moins l’un de ces faux sites distribue activement des logiciels malveillants !**

> **Ce logiciel est expérimental et fait l’objet d’un développement actif.** Les techniques utilisées sont particulièrement audacieuses. Ce que tente de faire ce logiciel est insensé. Il pourrait endommager vos fichiers de sauvegarde — et cela arrivera probablement ! Il pourrait écraser vos sauvegardes, provoquer des conflits étranges, les faire disparaître ou vous faire pleurer. Sauvegardez tous les fichiers auxquels vous tenez avant d’utiliser ce logiciel.

Mais cela n’arrivera probablement pas. Le logiciel est très stable depuis longtemps.

> **N’utilisez pas ce logiciel si vous ne souhaitez pas réellement disposer de sauvegardes cloud pour les jeux « lua ». Si seul le message d’erreur Steam Cloud vous gêne, désactivez Steam Cloud dans les propriétés du jeu concerné.**

## Fonctionnement

Commençons par un peu d’histoire.

Il était une fois un outil appelé SteamTools. SteamTools prenait plus ou moins en charge les sauvegardes cloud.

Valve a ensuite corrigé la méthode (sacrilège) qu’utilisait SteamTools pour synchroniser les sauvegardes. Plus précisément, SteamTools réécrivait les requêtes vers l’AppID 760, celui des captures d’écran Steam. Toutes les requêtes Steam Cloud destinées à des AppID non possédés y étaient envoyées. Aucun préfixe propre à chaque jeu n’était créé : toutes les applications « lua » partageaient donc leurs sauvegardes. Des conflits pouvaient survenir lorsque plusieurs jeux utilisaient le même nom de fichier. Les sauvegardes étaient également répliquées dans le dossier `Steam/Userdata/<steamid>/<appid du jeu lua>` de chaque application « lua ».

SteamTools ne prenait pas du tout en charge les jeux utilisant Steam AutoCloud. Il affichait simplement un faux message de réussite pour ces jeux.

CloudRedirect redirige les requêtes Steam Cloud des jeux injectés vers Google Drive, OneDrive ou un dossier local, y compris pour les jeux AutoCloud. Tout reste intégré nativement au client Steam, mais les données sont réellement lues et écrites depuis ou vers votre compte cloud. Cette approche était bien plus difficile à mettre en œuvre qu’une simple redirection des lectures et écritures vers un AppID possédé par votre compte, mais elle était amusante à développer. Elle est également moins susceptible d’agacer Valve.

## Fonctionnement technique

Sous Windows, CloudRedirect se compose d’une DLL C++ et d’une application compagnon WPF :

1. L’application compagnon copie la DLL dans votre dossier Steam et permet de vous connecter à votre fournisseur cloud.
2. La DLL intercepte les gestionnaires RPC internes des sauvegardes cloud de Steam grâce à ~~une interception de vtable~~ de la magie noire.
3. Lorsqu’un jeu « lua » tente de lire ou d’écrire des données de sauvegarde cloud, la DLL intercepte et redirige les appels. Si vous possédez le jeu, celui-ci utilise normalement Steam Cloud. Si un fichier « lua » sert uniquement à déverrouiller un DLC, le jeu utilise également Steam Cloud normalement.
4. Encore davantage de magie noire entre en jeu. Les sauvegardes se synchronisent. Les octets circulent. Tout est visible dans l’interface de Steam et se comporte comme la fonctionnalité Steam Cloud habituelle.

Le principe est globalement identique sous Linux, avec une application Flatpak et une bibliothèque chargée au démarrage de Steam.

## Fournisseurs cloud pris en charge

- **Google Drive**
- **OneDrive**
- **Cloudflare R2**
- **Fournisseurs compatibles S3** — AWS S3, MinIO, Backblaze B2, Wasabi, DigitalOcean Spaces et tout serveur S3 auto-hébergé.
- **Dossier local ou lecteur réseau** — ajouté à la demande d’un seul utilisateur, littéralement.

D’autres fournisseurs viendront avec le temps.

## Utilisation sous Windows

Téléchargez la dernière version depuis la [page des versions](https://github.com/Selectively11/CloudRedirect/releases).

Exécutez le fichier EXE. Choisissez votre mode : STfixer pour corriger les problèmes de ST, ou CloudRedirect pour profiter de toutes les fonctionnalités. Dans l’onglet de configuration, cliquez sur « Exécuter tous les correctifs ». Ouvrez ensuite l’onglet du fournisseur cloud, sélectionnez votre fournisseur et connectez-vous si nécessaire.

C’est tout. Lancez Steam et observez la magie.

## Utilisation sous Linux

Modifiez la configuration de SLSsteam et définissez `DisableCloud` sur `No`.

```bash
curl -fsSL headcrab.pages.dev | bash
```

Ouvrez l’application CloudRedirect et connectez-vous à un fournisseur.

Modifiez votre configuration SLS. Les jeux à synchroniser doivent être indiqués dans `AdditionalApps`. Cette exigence disparaîtra dans une prochaine version.

Lancez ensuite Steam et regardez vos jeux se synchroniser !

## Compilation depuis les sources sous Windows

### Prérequis

- Visual Studio 2022 (ou Build Tools), avec les charges de travail C++ et .NET 8
- CMake 3.20 ou version ultérieure

### Compilation

```bash
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

Ces commandes compilent la DLL C++ (`build/Release/cloud_redirect.dll`) et publient l’application WPF (`ui/bin/publish/CloudRedirect.exe`). La DLL est automatiquement intégrée à l’exécutable.

Ou ne le compilez pas ? Compiler des applications Windows est pénible.

## Compilation depuis les sources sous Linux

Ouh là là. Oui. Amusez-vous bien.

Vous devez compiler avec glibc 2.31 ou une version antérieure. Ubuntu 20.04 convient si vous aimez vous faire du mal. Une ancienne version de Fedora peut également convenir, tout comme Debian 11. Distrobox est la bonne solution ici. Ne perdez même pas votre temps à compiler sous votre distribution quotidienne : vous finiriez par vous battre avec elle sans raison. Distrobox existe précisément pour cela.

Sous Ubuntu 20.04, GCC 12 est requis, ainsi que les composants multilib 32 bits. La version système de CMake est très ancienne ; vous devrez la mettre à jour.

Ajoutez ensuite l’option `-DLINUX_32BIT=ON`, et le tour est joué.

Compiler pour des distributions atypiques, n’est-ce pas _amusant_ ?

## Contribution

CloudRedirect est un logiciel libre. Les pull requests sont les bienvenues. J’adore les pull requests.

J’aime moins les forks maintenus séparément. Vous avez bien sûr le droit de créer un fork et d’en faire ce que vous voulez, mais si vous développez quelque chose d’utile, corrigez un problème, ajoutez un fournisseur ou améliorez l’outil de quelque manière que ce soit, je préférerais que ces changements soient proposés au projet d’origine. Aidez-moi à vous aider ! Pensez à soumettre vos modifications sous forme de pull request plutôt que de les conserver uniquement dans un fork dérivé.
