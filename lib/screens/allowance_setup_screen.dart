import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class AllowanceSetupScreen extends StatefulWidget {
  const AllowanceSetupScreen({Key? key}) : super(key: key);

  @override
  State<AllowanceSetupScreen> createState() => _AllowanceSetupScreenState();
}

class _AllowanceSetupScreenState extends State<AllowanceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedFrequency = 'daily';
  DateTime _startDate = DateTime.now();
  int userId = 1;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_startDate);

    final success = await ApiService.addAllowance(
      userId: userId,
      amount: double.parse(_amountController.text.trim()),
      frequency: _selectedFrequency,
      startDate: formattedDate,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allowance saved')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save allowance')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Allowance")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: "Allowance Amount"),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Amount required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: InputDecoration(labelText: "Frequency"),
                items: ['daily', 'weekly', 'monthly']
                    .map((f) => DropdownMenuItem(
                        value: f, child: Text(f.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => _selectedFrequency = val!),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                    "Start Date: ${DateFormat.yMMMd().format(_startDate)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text("Save Allowance"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
