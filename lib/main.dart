import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TabeebAshiahApp());
}

class TabeebAshiahApp extends StatelessWidget {
  const TabeebAshiahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'طبيب أشعة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFA7BED3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B4965),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4965),
          primary: const Color(0xFF1B4965),
          secondary: const Color(0xFF62B6CB),
          surface: Colors.white,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
