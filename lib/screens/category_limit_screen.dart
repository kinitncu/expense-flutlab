import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryLimitScreen extends StatefulWidget {
  const CategoryLimitScreen({Key? key}) : super(key: key);

  @override
  State<CategoryLimitScreen> createState() => _CategoryLimitScreenState();
}

class _CategoryLimitScreenState extends State<CategoryLimitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food';
  String _selectedDuration = 'monthly';
  int userId = 1;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'School'
  ];

  final List<String> _durations = ['daily', 'weekly', 'monthly'];

  Future<void> _submitLimit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ApiService.setCategoryLimit(
        userId: userId,
        category: _selectedCategory,
        limitAmount: double.parse(_amountController.text.trim()),
        duration: _selectedDuration,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ Limit set for $_selectedCategory ($_selectedDuration)'
            : '❌ Failed to set limit'),
      ));

      if (success) {
        _amountController.clear();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Category Limit")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              SizedBox(height: 16),

              // Duration Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                decoration: InputDecoration(
                  labelText: "Duration",
                  border: OutlineInputBorder(),
                ),
                items: _durations
                    .map((dur) => DropdownMenuItem(
                          value: dur,
                          child: Text(dur.capitalize()),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDuration = val!),
              ),
              SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Limit Amount (₱)",
                  hintText: "e.g. 500",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitLimit,
                  icon: Icon(Icons.check),
                  label: Text('Save Limit'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension for capitalizing duration display
extension StringCasing on String {
  String capitalize() =>
      isNotEmpty ? this[0].toUpperCase() + substring(1) : this;
}
