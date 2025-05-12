import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryLimitScreen extends StatefulWidget {
  const CategoryLimitScreen({Key? key}) : super(key: key);

  @override
  State<CategoryLimitScreen> createState() => _CategoryLimitScreenState();
}

class _CategoryLimitScreenState extends State<CategoryLimitScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Food';
  double _limitAmount = 0.0;
  final _amountController = TextEditingController();

  Future<void> _submitLimit() async {
    if (_formKey.currentState!.validate()) {
      await ApiService.setCategoryLimit(
        userId: 1,
        category: _selectedCategory,
        limitAmount: double.parse(_amountController.text),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Limit Set')));
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Category Limit")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Food', 'Transport', 'Entertainment', 'School']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Limit Amount'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _submitLimit, child: Text('Save Limit')),
            ],
          ),
        ),
      ),
    );
  }
}
