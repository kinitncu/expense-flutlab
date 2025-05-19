import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import '../providers/currency_provider.dart';

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
        SnackBar(content: Text('✅ Allowance saved')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save allowance')),
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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(title: Text("Set Allowance")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Enter your allowance settings:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Allowance Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "Allowance Amount (${currencyProvider.symbol})",
                  border: OutlineInputBorder(),
                  hintText: "e.g. 500.00",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Amount is required' : null,
              ),
              SizedBox(height: 20),

              // Frequency Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: InputDecoration(
                  labelText: "Allowance Frequency",
                  border: OutlineInputBorder(),
                ),
                items: ['daily', 'weekly', 'monthly']
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedFrequency = val!),
              ),
              SizedBox(height: 20),

              // Start Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    "Start Date: ${DateFormat.yMMMMd().format(_startDate)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(Icons.check_circle),
                  label: Text("Save Allowance"),
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
