import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AllowanceProvider with ChangeNotifier {
  double _currentAllowance = 0;
  double _remainingBalance = 0;
  DateTime _startDate = DateTime.now();

  double get currentAllowance => _currentAllowance;
  double get remainingBalance => _remainingBalance;
  DateTime get startDate => _startDate;

  Future<void> loadAllowance(int userId) async {
    final allowance = await ApiService.getCurrentAllowance(userId);
    _currentAllowance = double.tryParse(allowance['amount'].toString()) ?? 0;
    _remainingBalance = _currentAllowance - (await _getTotalSpending(userId));
    _startDate = DateTime.parse(allowance['start_date']);
    notifyListeners();
  }

  Future<double> _getTotalSpending(int userId) async {
    final expenses = await ApiService.getExpenses(userId);
    final emergencies = await ApiService.getEmergencies(userId);

    double total = expenses.fold(
        0, (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0));
    total += emergencies.fold(
        0, (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0));

    return total;
  }

  Future<bool> updateAllowance({
    required int userId,
    required double newAmount,
    String frequency = 'monthly',
  }) async {
    final success = await ApiService.addAllowance(
      userId: userId,
      amount: newAmount,
      frequency: frequency,
      startDate: DateTime.now().toString(),
    );

    if (success) {
      _currentAllowance = newAmount;
      _remainingBalance = newAmount - (await _getTotalSpending(userId));
      _startDate = DateTime.now();
      notifyListeners();
    }
    return success;
  }
}
