import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
    macOS: darwinSettings,
  );
  await _notificationsPlugin.initialize(settings);

  final androidPlugin = _notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
}

Future<void> scheduleDailyReminderNotification({
  required int id,
  required TimeOfDay time,
  required String title,
  required String body,
}) async {
  final androidDetails = AndroidNotificationDetails(
    'daily_mood_channel',
    'Rappels humeur',
    channelDescription: 'Rappels quotidiens pour noter ton humeur.',
    importance: Importance.high,
    priority: Priority.high,
  );
  const darwinDetails = DarwinNotificationDetails();
  final details = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );

  final notifTime = Time(time.hour, time.minute, 0);

  await _notificationsPlugin.showDailyAtTime(
    id,
    title,
    body,
    notifTime,
    details,
    androidAllowWhileIdle: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await _initNotifications();
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
      const BreathingPage(),
      const MoodFormPage(),
      const StatsPage(),
      const PricingPage(),
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
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'Respire',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Ressenti',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Vue d’ensemble',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}

class MoodEntry {
  MoodEntry({
    required this.date,
    required this.mood,
    required this.activity,
    required this.note,
  });

  final DateTime date;
  final int mood;
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
    'Une petite action aujourd’hui vaut mieux que dix idées demain.',
    'Respire, recentre-toi, puis fais juste le prochain petit pas.',
    'Ton futur toi te remerciera pour ce que tu fais maintenant.',
    'Même les journées moyennes comptent dans le long terme.',
    'Tu as déjà surmonté pire, tu peux gérer aujourd’hui.',
    'La constance bat la perfection, un jour après l’autre.',
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surface,
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

class BreathingPattern {
  final String id;
  final String label;
  final String description;
  final Duration inhale;
  final Duration hold;
  final Duration exhale;
  final Duration holdEnd;

  const BreathingPattern({
    required this.id,
    required this.label,
    required this.description,
    required this.inhale,
    this.hold = Duration.zero,
    required this.exhale,
    this.holdEnd = Duration.zero,
  });

  Duration get total => inhale + hold + exhale + holdEnd;
}

const breathingPatterns = <BreathingPattern>[
  BreathingPattern(
    id: 'doux',
    label: 'Doux',
    description: 'Apaiser et relâcher la pression.',
    inhale: Duration(seconds: 4),
    exhale: Duration(seconds: 6),
  ),
  BreathingPattern(
    id: 'reveil',
    label: 'Réveil',
    description: 'Réactiver doucement ton énergie.',
    inhale: Duration(seconds: 3),
    hold: Duration(seconds: 1),
    exhale: Duration(seconds: 3),
  ),
  BreathingPattern(
    id: 'concentration',
    label: 'Concentration',
    description: 'Stabiliser ton attention (4-4-4-4).',
    inhale: Duration(seconds: 4),
    hold: Duration(seconds: 4),
    exhale: Duration(seconds: 4),
    holdEnd: Duration(seconds: 4),
  ),
  BreathingPattern(
    id: 'sport',
    label: 'Sport',
    description: 'Rythme plus dynamique pour l’effort.',
    inhale: Duration(seconds: 2),
    exhale: Duration(seconds: 2),
  ),
  BreathingPattern(
    id: 'vivacite',
    label: 'Vivacité',
    description: 'Booster légèrement ta vivacité mentale.',
    inhale: Duration(seconds: 2),
    hold: Duration(seconds: 2),
    exhale: Duration(seconds: 2),
    holdEnd: Duration(seconds: 1),
  ),
];

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with SingleTickerProviderStateMixin {
  late BreathingPattern _current;
  late AnimationController _controller;
  bool _running = false;
  String _lastPhase = '';

  @override
  void initState() {
    super.initState();
    _current = breathingPatterns.first;
    _controller = AnimationController(
      vsync: this,
      duration: _current.total,
    )..addListener(_onTick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    final phase = _currentPhase(_controller.value);
    if (phase != _lastPhase && phase.isNotEmpty) {
      _lastPhase = phase;
      HapticFeedback.lightImpact();
    }
    setState(() {});
  }

  String _currentPhase(double t) {
    final total = _current.total.inMilliseconds.toDouble();
    final inhaleEnd = _current.inhale.inMilliseconds / total;
    final holdEnd = (_current.inhale + _current.hold).inMilliseconds / total;
    final exhaleEnd =
        (_current.inhale + _current.hold + _current.exhale).inMilliseconds /
            total;

    if (t < inhaleEnd) return 'inspire';
    if (t < holdEnd && _current.hold > Duration.zero) return 'garde';
    if (t < exhaleEnd) return 'expire';
    if (_current.holdEnd > Duration.zero) return 'garde_fin';
    return '';
  }

  void _toggleRun() {
    if (_running) {
      _controller.stop();
    } else {
      _controller
        ..duration = _current.total
        ..repeat();
    }
    setState(() => _running = !_running);
  }

  void _changePattern(BreathingPattern p) {
    setState(() {
      _current = p;
      _lastPhase = '';
      _controller
        ..duration = _current.total
        ..reset();
      if (_running) {
        _controller.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = _currentPhase(_controller.value);
    final colorScheme = Theme.of(context).colorScheme;

    double sizeFactor;
    switch (phase) {
      case 'inspire':
        sizeFactor = 1.0;
        break;
      case 'expire':
        sizeFactor = 0.8;
        break;
      default:
        sizeFactor = 0.9;
    }

    String phaseLabel;
    switch (phase) {
      case 'inspire':
        phaseLabel = 'Inspire';
        break;
      case 'expire':
        phaseLabel = 'Expire';
        break;
      case 'garde':
        phaseLabel = 'Garde l’air';
        break;
      case 'garde_fin':
        phaseLabel = 'Repos';
        break;
      default:
        phaseLabel = _running ? 'Respire' : 'Prêt ?';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: breathingPatterns.map((p) {
                final selected = p.id == _current.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(p.label),
                    selected: selected,
                    onSelected: (_) => _changePattern(p),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _current.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 200 * sizeFactor,
            height: 200 * sizeFactor,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.8),
                  colorScheme.primaryContainer,
                ],
              ),
            ),
            child: Center(
              child: Text(
                phaseLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: colorScheme.onPrimary),
              ),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _toggleRun,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            label: Text(_running ? 'Pause' : 'Démarrer'),
          ),
        ],
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
              'Comment te sens-tu aujourd’hui ?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                    value: 1, icon: Icon(Icons.sentiment_very_dissatisfied)),
                ButtonSegment(value: 2, icon: Icon(Icons.sentiment_dissatisfied)),
                ButtonSegment(value: 3, icon: Icon(Icons.sentiment_neutral)),
                ButtonSegment(value: 4, icon: Icon(Icons.sentiment_satisfied)),
                ButtonSegment(
                    value: 5, icon: Icon(Icons.sentiment_very_satisfied)),
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
                DropdownMenuItem(
                    value: 'Famille', child: Text('Famille / amis')),
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
                hintText: 'Ce qui t’a marqué aujourd’hui...',
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
            'Aucun ressenti enregistré pour l’instant.\n\nCommence par noter ta journée dans l’onglet "Ressenti".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final last7 = _entries
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 7))))
        .toList();
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
            'Vue d’ensemble de ton humeur (7 derniers jours)',
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
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  static const _reminderId = 1001;

  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  String _mode = 'auto';
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('reminder_enabled') ?? false;
      final h = prefs.getInt('reminder_hour');
      final m = prefs.getInt('reminder_minute');
      if (h != null && m != null) {
        _time = TimeOfDay(hour: h, minute: m);
      }
      _mode = prefs.getString('reminder_mode') ?? 'auto';
      _customController.text =
          prefs.getString('reminder_custom_text') ?? '';
    });
  }

  Future<void> _saveAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _enabled);
    await prefs.setInt('reminder_hour', _time.hour);
    await prefs.setInt('reminder_minute', _time.minute);
    await prefs.setString('reminder_mode', _mode);
    await prefs.setString(
      'reminder_custom_text',
      _customController.text.trim(),
    );

    await _notificationsPlugin.cancel(_reminderId);
    if (_enabled) {
      final body = _mode == 'auto'
          ? 'Note ton humeur du jour et découvre la phrase du jour.'
          : (_customController.text.trim().isEmpty
              ? 'Petit rappel bienveillant pour toi.'
              : _customController.text.trim());
      await scheduleDailyReminderNotification(
        id: _reminderId,
        time: _time,
        title: 'Rappel quotidien',
        body: body,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rappel mis à jour.')),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
      await _saveAndSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'L’application reste totalement utilisable gratuitement. '
              'Si tu le souhaites, tu peux soutenir le projet et débloquer '
              'quelques bonus discrets.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Version actuelle',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text('• Accès complet aux phrases de motivation'),
                    Text('• Suivi de l’humeur et des activités'),
                    Text('• Graphiques sur 7 jours'),
                    Text('• Bannières publicitaires discrètes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.primaryContainer.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pass Premium (idée)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('Pensé comme un achat unique modeste (~3,99 € par ex.).'),
                    const SizedBox(height: 12),
                    const Text('Inclurait par exemple :'),
                    const Text('• Retrait complet des bannières publicitaires'),
                    const Text('• Thèmes visuels supplémentaires'),
                    const Text('• Futures fonctionnalités IA pour adapter les phrases'),
                    const Text('• Export des données de ressenti'),
                    const SizedBox(height: 16),
                    Text(
                      'Important : cette section est pour l’instant purement '
                      'informatique / conceptuelle. Le paiement in-app n’est '
                      'pas encore connecté.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Paiement non encore configuré (démo visuelle uniquement).',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Bientôt disponible'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rappel quotidien',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              title: const Text('Activer le rappel'),
              value: _enabled,
              onChanged: (value) async {
                setState(() => _enabled = value);
                await _saveAndSchedule();
              },
            ),
            ListTile(
              title: const Text('Heure du rappel'),
              subtitle: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              onTap: _pickTime,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Texte automatique (humeur + phrase du jour)'),
              value: 'auto',
              groupValue: _mode,
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _mode = v);
                await _saveAndSchedule();
              },
            ),
            RadioListTile<String>(
              title: const Text('Texte personnalisé'),
              value: 'custom',
              groupValue: _mode,
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _mode = v);
                await _saveAndSchedule();
              },
            ),
            if (_mode == 'custom')
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _customController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ton message de rappel (motivation, note, etc.)',
                  ),
                  onSubmitted: (_) => _saveAndSchedule(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
