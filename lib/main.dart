import 'dart:convert';
import 'dart:io';

import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/chat_provider.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/name_suggestion/name_provider.dart';
import 'package:adde/pages/note/note_provider.dart';
import 'package:adde/pages/notification/NotificationSettingsProvider.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:adde/pages/profile/locale_provider.dart';
import 'package:adde/auth/authentication_gate.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:adde/theme/theme_data.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Entry point of the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Attempt to restore saved session
  final sessionData = await _getSavedSession();
  final userId = sessionData['userId'];
  final email = sessionData['email'];

  // Initialize providers
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  final notificationSettingsProvider = NotificationSettingsProvider();

  await Future.wait([
    localeProvider.loadLocale(),
    themeProvider.loadTheme(),
    notificationSettingsProvider.loadSettings(),
  ]);

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => NameProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: notificationSettingsProvider),
        Provider(create: (_) => NotificationService()),
      ],
      child: MyApp(userId: userId, email: email),
    ),
  );
}

// Retrieve and validate saved Supabase session
Future<Map<String, String?>> _getSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionString = prefs.getString('supabase_session');
  if (sessionString == null) return {'userId': null, 'email': null};

  try {
    final sessionJson = jsonDecode(sessionString);
    if (sessionJson is Map<String, dynamic>) {
      final response = await Supabase.instance.client.auth.recoverSession(
        sessionString,
      );
      return {'userId': response.user?.id, 'email': response.user?.email};
    }
  } catch (_) {
    // Clear invalid session
    await prefs.remove('supabase_session');
  }
  return {'userId': null, 'email': null};
}

// Splash screen widget
class SplashScreen extends StatefulWidget {
  final String? userId;
  final String? email;

  const SplashScreen({super.key, this.userId, this.email});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkConnectivityAndProceed();
  }

  // Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // Show no internet dialog
  void _showNoInternetDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              l10n.noInternetTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              l10n.noInternetMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkConnectivityAndProceed();
                },
                child: Text(
                  l10n.retryButton,
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Check connectivity and navigate to appropriate screen
  Future<void> _checkConnectivityAndProceed() async {
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      _showNoInternetDialog();
      return;
    }

    // Navigate after a brief delay for splash screen effect
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  widget.userId != null
                      ? BottomPageNavigation(
                        user_id: widget.userId!,
                        email: widget.email,
                      )
                      : const AuthenticationGate(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assistant,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main application widget
class MyApp extends StatelessWidget {
  final String? userId;
  final String? email;

  const MyApp({super.key, this.userId, this.email});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Adde Assistance App',
          theme: ThemeModes.lightMode,
          darkTheme: ThemeModes.darkMode,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('am')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback:
              (deviceLocale, supportedLocales) => localeProvider.locale,
          home: SplashScreen(userId: userId, email: email),
        );
      },
    );
  }
}
