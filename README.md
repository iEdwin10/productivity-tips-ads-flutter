# Productivity Tips Ads (Flutter)

Application Flutter simple (Android + iOS) qui affiche des astuces de productivité et une bannière de pub (AdMob) pour générer un petit revenu passif.

## Principe

- Une seule base de code Flutter pour **Android et iOS**.[web:36][web:39]
- Liste d’astuces de productivité affichées au hasard.
- Bannière publicitaire via le plugin `google_mobile_ads`, supporté officiellement par Google pour Flutter.[web:34][web:43]
- Pas de backend, pas de compte, aucune donnée personnelle gérée directement dans le code (seules les données nécessaires à AdMob sont collectées via le SDK officiel).

## Installation du projet

1. Installer Flutter sur ta machine (voir doc officielle Flutter).
2. Cloner ce dépôt :
   ```bash
   git clone https://github.com/iEdwin10/productivity-tips-ads-flutter.git
   cd productivity-tips-ads-flutter
   ```
3. (Option recommandé) Lancer :
   ```bash
   flutter create .
   ```
   Cela génère les dossiers `android/` et `ios/` manquants à partir du `pubspec.yaml` existant, comme décrit dans la documentation/Stack Overflow.[web:36][web:42]
4. Récupérer les dépendances :
   ```bash
   flutter pub get
   ```
5. Lancer sur un device :
   ```bash
   flutter run
   ```

## Intégration AdMob (à faire avant publication)

Le code utilise pour l’instant les **Ad Unit IDs de test** recommandés par Google pour Flutter (`BannerAd.testAdUnitId`), ce qui est obligatoire pendant le dev.[web:34][web:35][web:44]

Pour passer en production :

1. Créer un compte AdMob et déclarer deux applis : une Android et une iOS.[web:34][web:35]
2. Créer pour chaque plateforme un bloc de bannière (Banner Ad Unit) et récupérer les IDs.
3. Mettre à jour :
   - L’`APPLICATION_ID` AdMob côté Android dans `android/app/src/main/AndroidManifest.xml` (clé `com.google.android.gms.ads.APPLICATION_ID`).[web:34][web:37]
   - L’ID d’appli AdMob côté iOS dans `ios/Runner/Info.plist`.
   - Remplacer `BannerAd.testAdUnitId` dans `lib/main.dart` par tes vrais `adUnitId` de production.

Pense aussi à :

- Vérifier que ta `minSdkVersion` Android est au moins 23/24 selon la version du SDK mobile ads utilisée, comme mentionné dans les notes de versions.[web:29][web:40]
- Tester longuement avec les IDs de test avant de basculer sur les IDs réels pour respecter les règles AdMob.[web:34][web:38]

## Personnalisation

- Modifie les textes des astuces dans `lib/main.dart` (tableau `_tips`).
- Change les couleurs / thème Flutter via `ThemeData` dans `MyApp`.

Cette appli est pensée pour être **simple, légère et avec très peu de maintenance** : aucune API externe (hors SDK de pubs), pas de base de données, juste du texte statique et une bannière pub.
