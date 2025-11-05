import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/effects_screen.dart';
import 'screens/files_screen.dart';
import 'providers/audio_provider.dart';
import 'providers/effects_provider.dart';
import 'utils/app_theme.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ses_degistirici/utils/ad_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  // Pre-load ads
  AdHelper.instance.loadBannerAd();
  AdHelper.instance.loadInterstitialAd();

  // Check and request permissions
  await _checkAndRequestPermissions();

  runApp(const VoiceChangerApp());
}

Future<void> _checkAndRequestPermissions() async {
  await [
    Permission.microphone,
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();
}

class VoiceChangerApp extends StatelessWidget {
  const VoiceChangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => EffectsProvider()),
        ChangeNotifierProvider.value(value: AdHelper.instance),
      ],
      child: MaterialApp(
        title: 'Ses Değiştirici',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EffectsScreen(),
    const FilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic),
            selectedIcon: Icon(Icons.mic),
            label: 'Kaydet',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_fix_high),
            selectedIcon: Icon(Icons.auto_fix_high),
            label: 'Efektler',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Dosyalarım',
          ),
        ],
      ),
    );
  }
}
