# Productivity Tips Ads (Flutter)

Application Flutter simple (Android + iOS) qui affiche des phrases de motivation, permet de noter son ressenti de la journée et affiche une vue d'ensemble graphique, avec une bannière publicitaire (AdMob) pour générer un petit revenu passif.

## Principe

- Une seule base de code Flutter pour **Android et iOS**.[web:36][web:39]
- Phrases de motivation affichées avec une petite animation et retour haptique pour rendre l’expérience plus dynamique.
- Formulaire pour que l’utilisateur saisisse son **ressenti (humeur, activité principale, note libre)**.
- Stockage local des ressentis via le plugin `shared_preferences`, adapté aux petites données persistantes dans Flutter.[web:59][web:57][web:62]
- Page "Vue d'ensemble" qui affiche un **graphique de l’humeur sur les 7 derniers jours** grâce à la librairie `fl_chart`, une lib de graphiques très personnalisable (line, bar, pie, etc.).[web:54][web:52][web:61]
- Bannière publicitaire via le plugin `google_mobile_ads`, supporté officiellement par Google pour Flutter (Android + iOS).[web:34][web:43][web:60]
- **Onglet discret "Plus"** avec une page de tarifs expliquant une future offre Premium (retrait des pubs, thèmes, IA, export de données), pour préparer une monétisation par achat in-app sans gêner l’expérience actuelle.[web:71][web:69]

Le but est de constituer une base pour, plus tard, brancher une IA qui analysera ces données et adaptera automatiquement les phrases de motivation et les conseils.

## Installation du projet

1. Installer Flutter sur ta machine (voir doc officielle Flutter).
2. Cloner ce dépôt :
   ```bash
   git clone https://github.com/iEdwin10/productivity-tips-ads-flutter.git
   cd productivity-tips-ads-flutter
   ```
3. Générer la structure complète (android/ios, etc.) :
   ```bash
   flutter create .
   ```
   Cette commande crée les dossiers natifs manquants à partir du `pubspec.yaml`, comme décrit dans la documentation/Stack Overflow.[web:36][web:42]
4. Récupérer les dépendances :
   ```bash
   flutter pub get
   ```
5. Lancer sur un device :
   ```bash
   flutter run
   ```

## Écrans principaux

- **Motivation** :
  - Carte animée avec une phrase de motivation.
  - Bouton "Nouvelle phrase" avec légère vibration (haptique) pour donner du feedback.
- **Ressenti** :
  - Sélecteur d’humeur (5 niveaux avec icônes). 
  - Liste déroulante pour l’activité principale (travail, études, famille, loisir, repos).
  - Champ texte pour décrire sa journée.
  - Bouton pour enregistrer le ressenti (stocké localement en JSON dans `SharedPreferences`).[web:59][web:57]
- **Vue d'ensemble** :
  - Récupère tous les ressentis.
  - Affiche un **graphe en ligne** de l’humeur des 7 derniers jours avec `LineChart` de `fl_chart` (courbe lissée, points, axes annotés).[web:52][web:54][web:58]
- **Plus (Tarifs / Premium)** :
  - Page très discrète qui présente la différence entre la version gratuite actuelle et une idée de **Pass Premium** (retrait des pubs, thèmes supplémentaires, futures fonctionnalités IA, export des données).
  - La page est purement informative pour l’instant : aucun paiement réel n’est branché. Elle prépare le terrain pour une future offre d’**achat "Retirer les pubs" ou abonnement**, comme recommandé par les stratégies de monétisation modernes (offrir un upsell ad-free en complément des pubs).[web:71][web:67][web:73]

## Intégration AdMob (à faire avant publication)

Le code utilise pour l’instant les **Ad Unit IDs de test** recommandés par Google pour Flutter (`BannerAd.testAdUnitId`), ce qui est obligatoire pendant le dev.[web:34][web:35][web:38]

Pour passer en production :

1. Créer un compte AdMob et déclarer deux applis : une Android et une iOS.[web:34][web:35]
2. Créer pour chaque plateforme un bloc de bannière (Banner Ad Unit) et récupérer les IDs.
3. Mettre à jour :
   - L’`APPLICATION_ID` AdMob côté Android dans `android/app/src/main/AndroidManifest.xml` sous la clé `com.google.android.gms.ads.APPLICATION_ID`.[web:34][web:37]
   - L’ID d’appli AdMob côté iOS dans `ios/Runner/Info.plist`.
   - Remplacer `BannerAd.testAdUnitId` dans `lib/main.dart` par tes vrais `adUnitId` de production.[web:34][web:43][web:60]

## "Backend" et futur IA

- Le stockage actuel est purement **local** (SharedPreferences) :
  - Pas de serveur à maintenir.
  - Moins de complexité, les données restent sur l’appareil de l’utilisateur.[web:59][web:55]  
- Plus tard, tu pourras :
  - soit synchroniser ces données avec un backend (Firebase, Supabase, etc.),
  - soit faire tourner un modèle d’IA directement côté client (on-device) pour personnaliser les phrases de motivation.
  - soit intégrer un **SDK de paywall / achats in-app** comme `in_app_purchases_paywall_ui`, RevenueCat ou Adapty pour connecter réellement la page Premium aux achats stores.[web:69][web:73][web:78]

L’architecture du code sépare déjà le modèle `MoodEntry`, le repository local et les écrans, ce qui facilitera l’ajout d’une couche IA, d’un backend distant ou d’une vraie gestion d’abonnements / achats in-app plus tard.
