import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'services/database_service.dart';

void main() {
  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Master Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAlignment.stretch,
            children: [
              const Icon(Icons.menu_book_rounded, size: 72, color: Colors.indigoAccent),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Vocab Master',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your target track to begin learning offline',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),
              _TrackCard(
                title: 'English Vocabulary',
                subtitle: 'Pure English definitions, simple examples & phonetics.',
                icon: Icons.language,
                color: Colors.indigoAccent,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen(language: 'english')),
                  );
                },
              ),
              const SizedBox(height: 16),
              _TrackCard(
                title: 'French Vocabulary',
                subtitle: 'Learn French explained clearly through English.',
                icon: Icons.translate,
                color: Colors.tealAccent,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen(language: 'french')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TrackCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String language;
  const HomeScreen({super.key, required this.language});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts tts = FlutterTts();
  List<WordModel> words = [];
  int currentWordIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
    _configureTts();
  }

  void _configureTts() async {
    await tts.setLanguage(widget.language == 'english' ? 'en-US' : 'fr-FR');
    await tts.setSpeechRate(0.45);
  }

  Future<void> _loadWords() async {
    List<WordModel> loadedWords = await DatabaseService.instance.getWordsByTrackAndLevel(
      widget.language,
      1,
    );
    setState(() {
      words = loadedWords;
      isLoading = false;
    });

    DatabaseService.instance.checkForNewLevelsOnline(widget.language, 1);
  }

  void _speak(String text) async {
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = widget.language == 'english';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'English Track' : 'French Track'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Track',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : words.isEmpty
              ? const Center(child: Text("No words found for this level."))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: (currentWordIndex + 1) / words.length,
                        backgroundColor: Colors.white10,
                        color: isEnglish ? Colors.indigoAccent : Colors.tealAccent,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Level 1", style: TextStyle(color: Colors.grey[400])),
                          Text(
                            "${currentWordIndex + 1} / ${words.length} Words",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: const Color(0xFF0F172A),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isEnglish
                                            ? Colors.indigo.withOpacity(0.3)
                                            : Colors.teal.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        words[currentWordIndex].partOfSpeech,
                                        style: TextStyle(
                                          color: isEnglish ? Colors.indigoAccent : Colors.tealAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, size: 28),
                                      onPressed: () => _speak(words[currentWordIndex].word),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  words[currentWordIndex].word,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  words[currentWordIndex].phonetics,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const Divider(height: 32, color: Colors.white10),
                                const Text(
                                  "DEFINITION",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  words[currentWordIndex].definition,
                                  style: const TextStyle(fontSize: 16, height: 1.4),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "EXAMPLES",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "• ${words[currentWordIndex].exampleEn}",
                                  style: const TextStyle(fontSize: 14, height: 1.4),
                                ),
                                if (words[currentWordIndex].exampleFr != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "• FR: ${words[currentWordIndex].exampleFr}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.tealAccent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: currentWordIndex > 0
                                ? () => setState(() => currentWordIndex--)
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Previous"),
                          ),
                          ElevatedButton.icon(
                            onPressed: currentWordIndex < words.length - 1
                                ? () => setState(() => currentWordIndex++)
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Next"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
