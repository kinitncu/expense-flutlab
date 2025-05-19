import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_screen.dart';
import 'expense_log_and_history_screen.dart'; // Combined screen import
import 'emergency_screen.dart';
import 'profile_screen.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ExpenseLogAndHistoryScreen(), // Combined screen
    EmergencyScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Log Expense and History',
    'Emergency Expenses',
    'User Profile',
  ];

  Color _getLightPastelColor(Color color) {
    return Color.lerp(color, Colors.white, 0.8)!;
  }

  Color _getNavigationBarColor(Color color, bool isDarkMode) {
    return isDarkMode
        ? Colors.grey[900]!
        : Color.lerp(color, Colors.white, 0.6)!;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final selectedColor = themeProvider.selectedColor.color;
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor =
        isDarkMode ? Colors.grey[900] : _getLightPastelColor(selectedColor);

    final textColor = isDarkMode
        ? Colors.white.withOpacity(0.90)
        : Colors.black.withOpacity(0.87);

    final navBarBackgroundColor =
        _getNavigationBarColor(selectedColor, isDarkMode);
    final selectedItemColor = selectedColor;
    final unselectedItemColor = isDarkMode ? Colors.grey[400] : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: selectedColor,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: textColor,
                displayColor: textColor,
              ),
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        backgroundColor: navBarBackgroundColor,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Log & History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
