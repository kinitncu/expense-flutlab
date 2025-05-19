import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorSelection {
  grey('Grey', Colors.blueGrey),
  red('Red', Colors.red),
  deepPurple('Deep Purple', Colors.deepPurple),
  purple('Purple', Colors.purple),
  brown('Brown', Colors.brown),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink);

  const ColorSelection(this.label, this.color);

  final String label;
  final Color color;
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ColorSelection _selectedColor = ColorSelection.blue;

  bool get isDarkMode => _isDarkMode;
  ColorSelection get selectedColor => _selectedColor;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setColor(ColorSelection color) {
    _selectedColor = color;
    _saveTheme();
    notifyListeners();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final colorIndex =
        prefs.getInt('selectedColor') ?? ColorSelection.blue.index;
    _selectedColor = ColorSelection.values[colorIndex];
    notifyListeners();
  }

  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    prefs.setInt('selectedColor', _selectedColor.index);
  }
}
