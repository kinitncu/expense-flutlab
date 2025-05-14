import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/user_setup_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isUserSetup() async {
    try {
      final user = await ApiService.getUser();
      return user['name'] != null && user['avatar'] != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: FutureBuilder<bool>(
        future: isUserSetup(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data! ? const HomeScreen() : const UserSetupScreen();
        },
      ),
    );
  }
}
