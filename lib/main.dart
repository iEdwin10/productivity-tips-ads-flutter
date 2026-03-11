import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astuce productive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TipsScreen(),
    );
  }
}

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final _tips = const [
    'Planifie ta journée la veille pour démarrer plus vite demain.',
    'Commence par la tâche la plus importante avant de regarder tes mails.',
    'Coupe les notifications non essentielles pendant que tu te concentres.',
    'Fais une pause de 5 minutes toutes les 55 minutes de travail.',
    'Note tes idées dès qu\'elles arrivent pour libérer ta mémoire.',
    'Trie ta to‑do en trois catégories : maintenant, plus tard, peut‑être.',
    'Automatise ce que tu répètes souvent (raccourcis, modèles, scripts).',
    'Fixe‑toi un objectif unique pour la journée plutôt qu\'une liste infinie.',
    'Range ton espace de travail en 2 minutes à la fin de la journée.',
    'Utilise des deadlines réalistes mais visibles pour chaque mini‑tâche.',
  ];

  int _index = 0;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final banner = BannerAd(
      adUnitId: BannerAd.testAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _nextTip() {
    setState(() {
      _index = (_index + 1) % _tips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Astuce productive'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _tips[_index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              onPressed: _nextTip,
              child: const Text('Astuce suivante'),
            ),
          ),
          if (_bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
