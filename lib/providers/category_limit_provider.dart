import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryLimitProvider with ChangeNotifier {
  Map<String, double> _limits = {};
  String _selectedDuration = 'monthly';

  Map<String, double> get limits => _limits;
  String get selectedDuration => _selectedDuration;

  Future<void> loadLimits(int userId) async {
    _limits = await ApiService.getCategoryLimits(userId, _selectedDuration);
    notifyListeners();
  }

  Future<bool> setLimit({
    required int userId,
    required String category,
    required double limit,
  }) async {
    final success = await ApiService.setCategoryLimit(
      userId: userId,
      category: category,
      limitAmount: limit,
      duration: _selectedDuration,
    );

    if (success) {
      await loadLimits(userId);
    }
    return success;
  }

  Future<bool> removeLimit({
    required int userId,
    required String category,
  }) async {
    final success = await ApiService.setCategoryLimit(
      userId: userId,
      category: category,
      limitAmount: 0,
      duration: _selectedDuration,
    );

    if (success) {
      await loadLimits(userId);
    }
    return success;
  }

  void setDuration(String duration) {
    _selectedDuration = duration;
    notifyListeners();
  }
}
