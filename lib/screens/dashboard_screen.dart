import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'allowance_setup_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> expenses = [];
  double total = 0.0;
  double forecast = 0.0;
  double allowance = 0.0;
  double balance = 0.0;
  Map<String, double> dailyTotals = {};
  Map<String, double> categoryTotals = {};
  Map<String, double> categoryLimits = {};
  bool showDailyReminder = false;
  bool showLowBalanceWarning = false;
  bool showEmergencyFundWarning = false;
  String userName = '';
  String? avatarBase64;
  int userId = 1;

  final List<String> quotes = [
    "Save money, and money will save you.",
    "A budget is telling your money where to go.",
    "Don’t go broke trying to look rich.",
    "Financial freedom is freedom of choice.",
    "Every peso saved is a peso earned.",
  ];

  String getDailyQuote() {
    final index = DateTime.now().day % quotes.length;
    return quotes[index];
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    loadExpenses();
  }

  Future<void> loadUser() async {
    final user = await ApiService.getUser(userId);
    userName = user['name'] ?? '';
    avatarBase64 = user['avatar'];
    setState(() {});
  }

  void loadExpenses() async {
    final data = await ApiService.getExpenses(userId);
    final limits = await ApiService.getCategoryLimits(userId);
    double runningTotal = 0.0;
    Map<String, double> tempDaily = {};
    Map<String, double> tempCategory = {};

    for (var item in data) {
      final amount = double.tryParse(item['amount']) ?? 0.0;
      final date = item['expense_date'];
      final category = item['category'];

      runningTotal += amount;
      tempDaily[date] = (tempDaily[date] ?? 0) + amount;
      tempCategory[category] = (tempCategory[category] ?? 0) + amount;
    }

    final last30 =
        tempDaily.values.toList().reversed.take(30).toList().reversed.toList();
    final forecasted = calculateForecast(last30);

    final allow = await ApiService.getCurrentAllowance(userId);
    final allowAmount = double.tryParse(allow['amount'].toString()) ?? 0.0;
    final startDate = DateTime.parse(allow['start_date']);
    final frequency = allow['frequency'];
    final remaining = allowAmount - runningTotal;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayLogged = data.any((e) => e['expense_date'] == todayStr);
    final emergencies = await ApiService.getEmergencies(userId);
    final totalEmergency = emergencies.fold<double>(
        0.0, (sum, e) => sum + double.parse(e['amount']));

    setState(() {
      expenses = data;
      total = runningTotal;
      forecast = forecasted;
      dailyTotals = tempDaily;
      allowance = allowAmount;
      balance = remaining;
      categoryLimits = limits;
      categoryTotals = tempCategory;
      showDailyReminder = !todayLogged;
      showLowBalanceWarning = balance < 100;
      showEmergencyFundWarning = totalEmergency > 0 && totalEmergency < 100;
    });

    if (isResetDue(frequency, startDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResetDialog(
          allowance: allowAmount,
          balance: remaining,
          frequency: frequency,
        );
      });
    }
  }

  double calculateForecast(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<BarChartGroupData> getChartData() {
    final sortedDates = dailyTotals.keys.toList()..sort();
    return List.generate(sortedDates.length, (index) {
      final date = sortedDates[index];
      final amount = dailyTotals[date] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: amount, width: 12, color: Colors.blue)],
      );
    });
  }

  bool isResetDue(String frequency, DateTime startDate) {
    final today = DateTime.now();
    switch (frequency) {
      case 'daily':
        return today.difference(startDate).inDays >= 1;
      case 'weekly':
        return today.difference(startDate).inDays >= 7;
      case 'monthly':
        return today.month != startDate.month || today.year != startDate.year;
      default:
        return false;
    }
  }

  void _showResetDialog(
      {required double allowance,
      required double balance,
      required String frequency}) {
    final _newAmountController = TextEditingController();
    String selectedFrequency = frequency;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Reset Allowance Period"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Carry over ₱${balance.toStringAsFixed(2)}?"),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: InputDecoration(labelText: "Frequency"),
                  items: ['daily', 'weekly', 'monthly']
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f[0].toUpperCase() + f.substring(1)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedFrequency = val!;
                    });
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _newAmountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: "New Allowance Amount"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final newAmount =
                      double.tryParse(_newAmountController.text) ?? 0;
                  final today = DateTime.now();
                  final formatted = DateFormat('yyyy-MM-dd').format(today);

                  await ApiService.addAllowance(
                    userId: userId,
                    amount: newAmount,
                    frequency: selectedFrequency,
                    startDate: formatted,
                    carryOver: balance,
                  );

                  Navigator.pop(context);
                  loadExpenses();
                },
                child: Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlert(String message, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.warning, color: color),
        SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: color))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> alerts = [];

    if (showDailyReminder)
      alerts.add(_buildAlert(
          "❗ Don't forget to log your spending today!", Colors.orange));

    if (showLowBalanceWarning)
      alerts.add(_buildAlert(
          "⚠️ Your balance is low: ₱${balance.toStringAsFixed(2)}",
          Colors.red));

    if (showEmergencyFundWarning)
      alerts.add(_buildAlert(
          "⚠️ Emergency fund is low. Consider topping it up.",
          Colors.deepOrange));

    final avatarWidget = avatarBase64 != null && avatarBase64!.isNotEmpty
        ? CircleAvatar(
            radius: 40,
            backgroundImage: MemoryImage(base64Decode(avatarBase64!)),
          )
        : CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: avatarWidget),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Hello, $userName 👋",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              Text("💡 ${getDailyQuote()}",
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
              SizedBox(height: 16),
              ...alerts,
              Text("Total Spent: ₱${total.toStringAsFixed(2)}"),
              Text("Allowance: ₱${allowance.toStringAsFixed(2)}"),
              Text("Remaining Balance: ₱${balance.toStringAsFixed(2)}"),
              Text("Forecast (30-day avg): ₱${forecast.toStringAsFixed(2)}"),
              SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AllowanceSetupScreen()),
                    );
                  },
                  icon: Icon(Icons.edit_calendar),
                  label: Text("Set / Edit Allowance"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text("Daily Spending Chart",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: BarChart(BarChartData(barGroups: getChartData())),
              ),
              SizedBox(height: 20),
              Text("Category Budget Warnings",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...categoryTotals.entries.map((entry) {
                final category = entry.key;
                final spent = entry.value;
                final limit = categoryLimits[category];

                if (limit == null) return SizedBox();

                String message = "";
                Color color = Colors.green;

                final percent = spent / limit;

                if (percent >= 1.0) {
                  message =
                      "❗ Over limit in $category (₱${spent.toStringAsFixed(2)} / ₱${limit.toStringAsFixed(2)})";
                  color = Colors.red;
                } else if (percent >= 0.8) {
                  message =
                      "⚠️  Near limit in $category (₱${spent.toStringAsFixed(2)} / ₱${limit.toStringAsFixed(2)})";
                  color = Colors.orange;
                } else {
                  return SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(message, style: TextStyle(color: color)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
