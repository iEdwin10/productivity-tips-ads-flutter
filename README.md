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
- **Notifications locales quotidiennes** (via `flutter_local_notifications`) pour rappeler à l’utilisateur de noter son humeur et lui afficher la phrase du jour, avec gestion de la permission Android 13+.[web:84][web:85][web:88]

Le but est de constituer une base pour, plus tard, brancher une IA qui analysera ces données et adaptera automatiquement les phrases de motivation et les conseils.
