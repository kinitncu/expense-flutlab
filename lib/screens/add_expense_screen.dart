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
  String _category = 'Food';
  double _amount = 0.0;
  String _note = '';
  DateTime _selectedDate = DateTime.now();

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final success = await ApiService.addExpense(
        userId: 1, // Hardcoded for now
        category: _category,
        amount: _amount,
        date: formattedDate,
        note: _note,
      );

      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Expense Added!")));
        _formKey.currentState!.reset();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to add expense")));
      }
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Food', 'Transport', 'Entertainment', 'School']
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
                onSaved: (val) => _amount = double.tryParse(val ?? '0') ?? 0,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Note'),
                onSaved: (val) => _note = val ?? '',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                  TextButton(onPressed: _pickDate, child: Text('Pick Date'))
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitExpense,
                child: Text('Submit Expense'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
