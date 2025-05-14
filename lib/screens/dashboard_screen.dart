import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> expenses = [];
  List<double> yearlyAverages = [];
  Map<String, double> dailyTotals = {};
  Map<String, double> categoryTotals = {};
  Map<String, double> categoryLimits = {};

  double total = 0.0;
  double forecast = 0.0;
  double allowance = 0.0;
  double balance = 0.0;
  double emergencyTotal = 0.0;

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

  @override
  void initState() {
    super.initState();
    loadUser();
    loadExpenses();
  }

  Future<void> loadUser() async {
    final user = await ApiService.getUser(userId);
    setState(() {
      userName = user['name'] ?? '';
      avatarBase64 = user['avatar'];
    });
  }

  Future<void> loadExpenses() async {
    final data = await ApiService.getExpenses(userId);
    final emergencies = await ApiService.getEmergencies(userId);
    final yearlyData = await ApiService.getYearlyAverages(userId);
    final allow = await ApiService.getCurrentAllowance(userId);

    double runningTotal = 0.0;
    Map<String, double> tempDaily = {};
    Map<String, double> tempCategory = {};

    for (var item in data) {
      final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
      final date = item['expense_date'];
      final category = item['category'];

      runningTotal += amount;
      tempDaily[date] = (tempDaily[date] ?? 0) + amount;
      tempCategory[category] = (tempCategory[category] ?? 0) + amount;
    }

    final totalEmergency = emergencies.fold<double>(
      0.0,
      (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0.0),
    );
    runningTotal += totalEmergency;

    final averages = yearlyData;
    final forecasted = calculateForecast(averages);

    final allowAmount = double.tryParse(allow['amount'].toString()) ?? 0.0;
    final remaining = allowAmount - runningTotal;
    final frequency = allow['frequency'];
    final startDate = DateTime.parse(allow['start_date']);
    final limits = await ApiService.getCategoryLimits(userId, frequency);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayLogged = data.any((e) => e['expense_date'] == today);

    setState(() {
      expenses = data;
      total = runningTotal;
      forecast = forecasted;
      allowance = allowAmount;
      balance = remaining;
      emergencyTotal = totalEmergency;
      dailyTotals = tempDaily;
      categoryTotals = tempCategory;
      categoryLimits = limits;
      yearlyAverages = averages;

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

  double calculateForecast(List<double> yearlyAverages) {
    if (yearlyAverages.length < 2) {
      return yearlyAverages.isNotEmpty ? yearlyAverages.last : 0.0;
    }

    final n = yearlyAverages.length;
    final x = List.generate(n, (i) => i + 1);
    final y = yearlyAverages;

    final xAvg = x.reduce((a, b) => a + b) / n;
    final yAvg = y.reduce((a, b) => a + b) / n;

    final num = List.generate(n, (i) => (x[i] - xAvg) * (y[i] - yAvg))
        .reduce((a, b) => a + b);
    final den = List.generate(n, (i) => (x[i] - xAvg) * (x[i] - xAvg))
        .reduce((a, b) => a + b);

    final slope = num / den;
    final intercept = yAvg - slope * xAvg;
    return intercept + slope * (n + 1);
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

  void _showResetDialog({
    required double allowance,
    required double balance,
    required String frequency,
  }) {
    final _controller = TextEditingController();
    String selectedFreq = frequency;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Reset Allowance Period"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Carry over ₱${balance.toStringAsFixed(2)}?"),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedFreq,
              items: ['daily', 'weekly', 'monthly']
                  .map((f) =>
                      DropdownMenuItem(value: f, child: Text(f.toUpperCase())))
                  .toList(),
              onChanged: (val) => selectedFreq = val!,
              decoration: InputDecoration(labelText: "Frequency"),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "New Allowance Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(_controller.text) ?? 0;
              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

              await ApiService.addAllowance(
                userId: userId,
                amount: amount,
                frequency: selectedFreq,
                startDate: today,
                carryOver: balance,
              );

              Navigator.pop(context);
              loadExpenses();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("New allowance started.")),
              );
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> getChartData() {
    final sorted = dailyTotals.keys.toList()..sort();
    return List.generate(sorted.length, (i) {
      final date = sorted[i];
      final amount = dailyTotals[date] ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: amount, width: 12, color: Colors.blue)],
      );
    });
  }

  Widget _buildAlert(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  String getDailyQuote() {
    final index = DateTime.now().day % quotes.length;
    return quotes[index];
  }

  @override
  Widget build(BuildContext context) {
    final avatar = avatarBase64 != null && avatarBase64!.isNotEmpty
        ? CircleAvatar(
            radius: 40,
            backgroundImage: MemoryImage(base64Decode(avatarBase64!)))
        : CircleAvatar(radius: 40, child: Icon(Icons.person));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: avatar),
            SizedBox(height: 10),
            Center(
              child: Text("Hello, $userName 👋",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            Text("💡 ${getDailyQuote()}",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            SizedBox(height: 16),
            if (showDailyReminder)
              _buildAlert(
                  "❗ Don't forget to log your spending today!", Colors.orange),
            if (showLowBalanceWarning)
              _buildAlert(
                  "⚠️ Balance low: ₱${balance.toStringAsFixed(2)}", Colors.red),
            if (showEmergencyFundWarning)
              _buildAlert("⚠️ Emergency fund is low.", Colors.deepOrange),
            Text("Total Spent: ₱${total.toStringAsFixed(2)}"),
            Text("Allowance: ₱${allowance.toStringAsFixed(2)}"),
            Text("Remaining Balance: ₱${balance.toStringAsFixed(2)}"),
            Text("Emergency Total: ₱${emergencyTotal.toStringAsFixed(2)}"),
            Text("Forecast Next Year: ₱${forecast.toStringAsFixed(2)}"),
            SizedBox(height: 20),
            Text("📊 Daily Spending Chart",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
                height: 200,
                child: BarChart(BarChartData(barGroups: getChartData()))),
            SizedBox(height: 30),
            Text("📈 Yearly Trend with Forecast",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < yearlyAverages.length; i++)
                        FlSpot(i.toDouble(), yearlyAverages[i]),
                      FlSpot(yearlyAverages.length.toDouble(), forecast),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blue,
                    dotData: FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        int year = DateTime.now().year -
                            yearlyAverages.length +
                            value.toInt();
                        return Text("$year", style: TextStyle(fontSize: 10));
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 50),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
              )),
            ),
            SizedBox(height: 20),
            Text("🚨 Budget Warnings",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...categoryTotals.entries.map((e) {
              final limit = categoryLimits[e.key];
              if (limit == null) return SizedBox();
              final percent = e.value / limit;
              if (percent >= 1.0) {
                return Text(
                  "❗ Over limit in ${e.key} (₱${e.value.toStringAsFixed(2)} / ₱${limit.toStringAsFixed(2)})",
                  style: TextStyle(color: Colors.red),
                );
              } else if (percent >= 0.8) {
                return Text(
                  "⚠️ Near limit in ${e.key} (₱${e.value.toStringAsFixed(2)} / ₱${limit.toStringAsFixed(2)})",
                  style: TextStyle(color: Colors.orange),
                );
              }
              return SizedBox();
            }),
          ]),
        ),
      ),
    );
  }
}
