import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_study_assistant/services/auth_service.dart';
import 'package:smart_study_assistant/pages/home_page.dart';
import 'package:smart_study_assistant/pages/summarizer_page.dart';
import 'package:smart_study_assistant/pages/notes_library_page.dart';
import 'package:smart_study_assistant/pages/flashcards_page.dart';
import 'package:smart_study_assistant/pages/statistics_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Sign in anonymously for development/testing
  final authService = AuthService();
  try {
    final userId = authService.getCurrentUserId();
    if (userId == null) {
      await authService.signInAnonymously();
      print('App initialized with anonymous authentication');
    }
  } catch (e) {
    print('Error initializing auth: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Study Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  int _homePageKeyCounter = 0;
  final List<int> _navigationHistory = [0];
  late String _userId;
  late List<Widget> _pages;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _userId = _authService.getCurrentUserId() ?? 'test_user';
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      HomePage(
        userId: _userId,
        key: ValueKey('home-$_homePageKeyCounter'),
        onNavigate: _onNavItemTapped,
      ),
      SummarizerPage(userId: _userId),
      NotesLibraryPage(userId: _userId),
      FlashcardsPage(userId: _userId),
      StatisticsPage(userId: _userId),
    ];
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    // Prevent section-specific messages from appearing in other tabs.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    _navigationHistory.add(index);

    if (index == 0 && _selectedIndex != 0) {
      _homePageKeyCounter++;
      _buildPages();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleSystemBack() {
    if (_navigationHistory.length <= 1) {
      return;
    }

    _navigationHistory.removeLast();
    final previousIndex = _navigationHistory.last;

    if (previousIndex == 0 && _selectedIndex != 0) {
      _homePageKeyCounter++;
      _buildPages();
    }

    setState(() {
      _selectedIndex = previousIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navigationHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _handleSystemBack();
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Summarize',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(Icons.style),
              label: 'Flashcards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Stats',
            ),
          ],
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }
}

/// Placeholder page for features to be developed by other team members
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title Feature',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
