import 'package:flutter/material.dart';
import 'screens/user_setup_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  Future<bool> isUserSetup() async {
    try {
      final user = await ApiService.getUser(); // No ID passed = first user
      return user['name'] != null && user['avatar'] != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: isUserSetup(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data! ? HomeScreen() : UserSetupScreen();
        },
      ),
      routes: {
        '/home': (_) => HomeScreen(),
      },
    );
  }
}
