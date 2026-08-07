# Redirection vers le cloud

""Steam Cloud"" pour les jeux 'lua'.

**C'est la seule source officielle de CloudRedirect. Tous les autres sites Web ne sont pas gérés par moi ou sont autrement approuvés par ce projet. Au moins un de ces faux sites distribue activement des logiciels malveillants !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!**

> ****Ce logiciel est expérimental et en cours de développement actif.**** Les techniques sous-jacentes sont assez folles. Ce que ce logiciel essaie de faire est fou à tenter. Ce logiciel pourrait endommager vos fichiers de sauvegarde et le fera probablement ! Cela pourrait écraser vos sauvegardes, provoquer des conflits étranges, faire disparaître vos sauvegardes, vous faire pleurer. Sauvegardez toutes les sauvegardes qui vous intéressent avant d'utiliser ce logiciel.

Mais ce ne sera probablement pas le cas. C'est très solide depuis longtemps.

>****N'utilisez pas ceci si vous ne souhaitez pas activement des sauvegardes dans le cloud pour les jeux "lua". Si tout ce qui vous intéresse est l'erreur Steam Cloud, désactivez Steam Cloud dans les propriétés de ce jeu. ****

## Ce que ça fait

Tout d’abord, quelques anecdotes :

Il était une fois un outil appelé SteamTools. SteamTools prenait en charge la sauvegarde dans le cloud, en quelque sorte.

Plus tard, Valve a corrigé la chose (pécheresse) que SteamTools faisait pour synchroniser les sauvegardes. Plus précisément, SteamTools a réécrit les requêtes vers AppID 760, qui correspond aux captures d'écran Steam. Il y a envoyé toutes les requêtes Steam Cloud pour les AppID non -owned. Il n'a pas créé de préfixes pour chaque jeu individuel, ce qui signifie que chaque application Lua partageait les sauvegardes avec toutes les autres. Cela peut provoquer des conflits de sauvegarde si plusieurs jeux utilisent le même nom de fichier de sauvegarde. Cela signifie également que vos sauvegardes sont répliquées dans le dossier « Steam/Userdata/<steamid>/<appid for lua game> » pour chaque application Lua.

Il ne prenait pas non plus du tout en charge les jeux Steam AutoCloud. Cela afficherait simplement un faux message de réussite pour ces jeux.

Ce que fait _cet_ outil, c'est rediriger les requêtes Steam Cloud pour les jeux injectés vers Google Drive/OneDrive/un dossier local, y compris les jeux AutoCloud. Tout est natif dans le client Steam, mais les données réelles sont lues/écrites vers et depuis votre compte cloud. C'était beaucoup plus difficile à faire que de simplement rediriger la lecture/écriture vers un AppID appartenant à votre compte, mais c'était amusant à réaliser. Il est également moins susceptible d’énerver Valve.

## Comment ça marche

CloudRedirect pour Windows se compose d'une DLL C++ et d'une application compagnon WPF :

1. L'application compagnon est utilisée pour copier la DLL dans votre dossier Steam et permettre à l'utilisateur de se connecter à son fournisseur de cloud.
2. La DLL accroche les gestionnaires RPC de sauvegarde dans le cloud interne de Steam via ~~ interception vtable ~~ magie noire.
3. Lorsqu'un jeu Lua tente de lire ou d'écrire des données de sauvegarde dans le cloud, la DLL intercepte les appels et les redirige. Si le jeu appartient, le jeu utilise Steam Cloud normal comme prévu. Si un Lua est présent et déverrouille uniquement le DLC, le jeu utilisera Steam Cloud normal.
4. De plus en plus de magie noire se produit. Enregistre la synchronisation. Flux d’octets. Tout cela est visible dans l’interface utilisateur Steam et semble identique à la fonctionnalité Steam Cloud normale.

Même idée approximative sous Linux, mais impliquant à la place une application flatpak et une bibliothèque chargée au démarrage de Steam.
   
## Fournisseurs de cloud pris en charge

- **Google Drive**
- **OneDrive**
- **Cloudflare R2**
- **S3-Compatible** - AWS S3, MinIO, Backblaze B2, Wasabi, DigitalOcean Spaces et tout serveur self-hosted S3.
- **Dossier local / lecteur mappé** - à la demande d'un seul utilisateur.

Avec plus à venir au fil du temps.

## Utilisation (Windows)

Récupérez la dernière version sur la [page Versions](https://github.com/Selectively11/CloudRedirect/releases).

Exécutez le fichier EXE. Choisissez votre mode : le mode STfixer pour les corrections de bugs ST, le mode CloudRedirect pour les bonnes choses. Dans la configuration, cliquez sur « Exécuter tous les correctifs ». Accédez à l'onglet Fournisseur de cloud, sélectionnez votre fournisseur. S'il s'agit d'un fournisseur de cloud, connectez-vous.

C'est ça. Allez lancer Steam et observez la magie.

## Utilisation (Linux)

Modifiez votre configuration SLSsteam, définissez DisableCloud sur Non.


```curl -fsSL headcrab.pages.dev | bash```

Open the CloudRedirect app, sign into a provider.

Edit your SLS config. The games you want to sync must be specified under AdditionalApps in your SLS config. This requirement will go away in the future. 

Now launch Steam and watch your games sync!

## Building from source (Windows)

### Prerequisites

- Visual Studio 2022 (or Build Tools) with the C++ and .NET 8 workloads
- CMake 3.20+

### Build

```bash
cmake -B construire -G "Visual Studio 17 2022" -A x64
cmake --build construire la version --config
```

This builds both the C++ DLL (`build/Release/cloud_redirect.dll`) and publishes the WPF app (`ui/bin/publish/CloudRedirect.exe`). The DLL is automatically embedded into the executable.

Or don't build it? Building Windows apps is pain.

## Building from source (Linux)

Oooooh boy. Yeah. Have fun. 

You need to build against glibc 2.31 or older. Ubuntu 20.04 would work, if you dislike yourself. There's also an ancient version of Fedora that fits the bill. Or Debian 11. Distrobox is the way, here. Don't even bother trying to build under whatever distro you daily, you'll wind up fighting it for no reason. Distrobox exists for a reason. 

If you are building under Ubuntu 20.04, GCC 12 is needed along with the 32-bit multilib stuff. System cmake is ancient garbage, you'll have to update it.

Then specify -DLINUX_32BIT=ON and wham bam.

Isn't building for weird distros _fun?_

## Contibuting

CloudRedirect is open source. I welcome PRs. I love PRs.

I don't _love_ downstream forks. You have a right to fork and do what you want, but if you make something useful, if you fix issues...I'd much prefer they be sent upstream! Help me help you! If you identify a problem/add a provider/improve the tool in any way, please consider submitting your changes as a PR, rather than keeping them in a downstream fork.
