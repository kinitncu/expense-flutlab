import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currency = '₱ PHP';

  String get currency => _currency;
  String get symbol => _currency.split(' ')[0];

  void setCurrency(String newCurrency) {
    _currency = newCurrency;
    notifyListeners();
  }
}
