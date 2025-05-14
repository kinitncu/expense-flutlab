import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final _defaultCategories = [
    'Food',
    'Transport',
    'School',
    'Entertainment',
    'Health',
    'Others',
    'Custom'
  ];

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  int userId = 1;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final category = _selectedCategory == 'Custom'
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    final success = await ApiService.addExpense(
      userId: userId,
      category: category,
      amount: double.parse(_amountController.text.trim()),
      date: formattedDate,
      note: _noteController.text.trim(),
    );

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to add expense. Please try again.')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("➕ Add Expense")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Fill out the details below:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _defaultCategories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),

              // Custom Category Input
              if (_selectedCategory == 'Custom') ...[
                SizedBox(height: 10),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    labelText: "Custom Category",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Enter custom category'
                      : null,
                ),
              ],

              SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "Amount (₱)",
                  hintText: "Enter amount spent",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
              ),

              SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: "Note (optional)",
                  hintText: "e.g. Grab fare, school supplies...",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    Text("Date: ${DateFormat.yMMMMd().format(_selectedDate)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),

              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(Icons.check),
                  label: Text("Add Expense"),
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
