import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/user_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart'; // ✅ Import SplashScreen
import 'services/api_service.dart';
import 'providers/theme_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/allowance_provider.dart';
import 'providers/category_limit_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => AllowanceProvider()),
        ChangeNotifierProvider(create: (_) => CategoryLimitProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeProvider.selectedColor.color,
      brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
    );

    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor:
            themeProvider.selectedColor.color.withOpacity(0.1),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey[400],
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white.withOpacity(0.9),
              displayColor: Colors.white.withOpacity(0.9),
            ),
      ),
      home: SplashScreen(), // ✅ Set SplashScreen as initial screen
    );
  }
}
