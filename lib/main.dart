import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'Boost humeur',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MotivationPage(),
      const MoodFormPage(),
      const StatsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_currentIndex]),
            if (_bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Motivation',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Ressenti',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Vue d\'ensemble',
          ),
        ],
      ),
    );
  }
}

/// Modèle simple pour un enregistrement de ressenti.
class MoodEntry {
  MoodEntry({
    required this.date,
    required this.mood,
    required this.activity,
    required this.note,
  });

  final DateTime date;
  final int mood; // 1 à 5
  final String activity;
  final String note;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'mood': mood,
        'activity': activity,
        'note': note,
      };

  static MoodEntry fromJson(Map<String, dynamic> json) => MoodEntry(
        date: DateTime.parse(json['date'] as String),
        mood: json['mood'] as int,
        activity: json['activity'] as String,
        note: json['note'] as String,
      );
}

/// Petit "backend" local basé sur SharedPreferences pour stocker les ressentis.
class MoodRepository {
  static const _key = 'mood_entries_v1';

  static Future<List<MoodEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<MoodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<void> add(MoodEntry entry) async {
    final all = await loadAll();
    all.add(entry);
    await saveAll(all);
  }
}

class MotivationPage extends StatefulWidget {
  const MotivationPage({super.key});

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage>
    with SingleTickerProviderStateMixin {
  final _phrases = const [
    'Tu es plus proche que tu ne le crois.',
    'Une petite action aujourd\'hui vaut mieux que dix idées demain.',
    'Respire, recentre-toi, puis fais juste le prochain petit pas.',
    'Ton futur toi te remerciera pour ce que tu fais maintenant.',
    'Même les journées moyennes comptent dans le long terme.',
    'Tu as déjà surmonté pire, tu peux gérer aujourd\'hui.',
    'La constance bat la perfection, un jour après l\'autre.',
  ];

  int _index = 0;
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPhrase() {
    HapticFeedback.lightImpact();
    setState(() {
      _index = (_index + 1) % _phrases.length;
      _controller
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fade,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _phrases[_index],
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _nextPhrase,
                icon: const Icon(Icons.vibration),
                label: const Text('Nouvelle phrase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoodFormPage extends StatefulWidget {
  const MoodFormPage({super.key});

  @override
  State<MoodFormPage> createState() => _MoodFormPageState();
}

class _MoodFormPageState extends State<MoodFormPage> {
  int _mood = 3;
  String _activity = 'Travail';
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    final entry = MoodEntry(
      date: DateTime.now(),
      mood: _mood,
      activity: _activity,
      note: _noteController.text.trim(),
    );
    await MoodRepository.add(entry);
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ressenti enregistré. Merci !')),
    );
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment te sens-tu aujourd\'hui ?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, icon: Icon(Icons.sentiment_very_dissatisfied)),
                ButtonSegment(value: 2, icon: Icon(Icons.sentiment_dissatisfied)),
                ButtonSegment(value: 3, icon: Icon(Icons.sentiment_neutral)),
                ButtonSegment(value: 4, icon: Icon(Icons.sentiment_satisfied)),
                ButtonSegment(value: 5, icon: Icon(Icons.sentiment_very_satisfied)),
              ],
              selected: {_mood},
              onSelectionChanged: (values) {
                HapticFeedback.selectionClick();
                setState(() => _mood = values.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Activité principale de la journée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _activity,
              items: const [
                DropdownMenuItem(value: 'Travail', child: Text('Travail')),
                DropdownMenuItem(value: 'Études', child: Text('Études')), 
                DropdownMenuItem(value: 'Famille', child: Text('Famille / amis')), 
                DropdownMenuItem(value: 'Loisir', child: Text('Loisir / hobby')), 
                DropdownMenuItem(value: 'Repos', child: Text('Repos / santé')), 
              ],
              onChanged: (value) {
                if (value == null) return;
                HapticFeedback.selectionClick();
                setState(() => _activity = value);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Quelques mots sur ta journée (facultatif)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ce qui t\'a marqué aujourd\'hui... ',
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Enregistrer le ressenti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<MoodEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await MoodRepository.loadAll();
    setState(() {
      _entries = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Aucun ressenti enregistré pour l\'instant.\n\nCommence par noter ta journée dans l\'onglet "Ressenti".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final last7 = _entries.where((e) => e.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    last7.sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (var i = 0; i < last7.length; i++) {
      spots.add(FlSpot(i.toDouble(), last7[i].mood.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble de ton humeur (7 derniers jours)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    minY: 1,
                    maxY: 5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(
                      border: const Border(
                        left: BorderSide(),
                        bottom: BorderSide(),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 1:
                                return const Text('Très bas');
                              case 2:
                                return const Text('Bas');
                              case 3:
                                return const Text('Neutre');
                              case 4:
                                return const Text('Bon');
                              case 5:
                                return const Text('Très bon');
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= last7.length) {
                              return const SizedBox.shrink();
                            }
                            final date = last7[index].date;
                            return Text('${date.day}/${date.month}');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
