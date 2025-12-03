import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/intake/age_picker_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().init();
  await NotificationService().requestPermissions();
  await NotificationService().scheduleAllNotifications();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..loadSavedLanguage()),
      ],
      child: const OncoNutriApp(),
    ),
  );
}

class OncoNutriApp extends StatelessWidget {
  const OncoNutriApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'OncoNutri+',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('hi', ''),
            Locale('kn', ''),
            Locale('ta', ''),
            Locale('te', ''),
            Locale('ml', ''),
            Locale('mr', ''),
            Locale('gu', ''),
            Locale('bn', ''),
            Locale('pa', ''),
          ],
          home: const AuthCheckScreen(),
        );
      },
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Small delay for smoother experience
    await Future.delayed(const Duration(milliseconds: 500));

    final isLoggedIn = await AuthService.isLoggedIn();
    final hasCompletedIntake = await AuthService.hasCompletedIntake();

    if (!mounted) return;

    Widget nextScreen;

    if (isLoggedIn) {
      // Already logged in
      if (hasCompletedIntake) {
        nextScreen = const HomeScreen(); // Go straight to home
      } else {
        nextScreen = const AgePickerScreen(); // Complete intake
      }
    } else {
      // Not logged in - show login screen directly
      nextScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2A694)),
          ),
        ),
      ),
    );
  }
}


