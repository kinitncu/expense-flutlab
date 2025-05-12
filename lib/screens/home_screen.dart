import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'add_expense_screen.dart';
import 'expense_history_screen.dart';
import 'emergency_screen.dart';
import 'category_limit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    AddExpenseScreen(),
    ExpenseHistoryScreen(),
    EmergencyScreen(),
    CategoryLimitScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Add Expense',
    'History',
    'Emergency',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning), label: 'Emergency'),
        ],
      ),
    );
  }
}
