import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int userId = 1;
  List<Map<String, dynamic>> _emergencies = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencies();
  }

  Future<void> _loadEmergencies() async {
    final data = await ApiService.getEmergencies(userId);
    setState(() {
      _emergencies = data;
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = await ApiService.logEmergency(
      userId: userId,
      amount: double.parse(_amountController.text.trim()),
      date: formattedDate,
      note: _noteController.text.trim(),
    );

    if (success) {
      _amountController.clear();
      _noteController.clear();
      setState(() => _selectedDate = DateTime.now());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Emergency expense logged')),
      );

      _loadEmergencies();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to log emergency expense')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildEmergencyItem(Map<String, dynamic> e) {
    final dateLabel = e['date'] ?? e['emergency_date'] ?? 'Unknown Date';
    final parsed = DateTime.tryParse(dateLabel);
    final displayDate =
        parsed != null ? DateFormat.yMMMMd().format(parsed) : dateLabel;

    final amount = double.tryParse(e['amount'].toString()) ?? 0;
    final note = e['note'] ?? '';

    return ListTile(
      leading: Icon(Icons.warning_amber, color: Colors.deepOrange),
      title: Text("₱${amount.toStringAsFixed(2)}"),
      subtitle: Text(note.isNotEmpty ? "$note\n$displayDate" : displayDate),
      isThreeLine: note.isNotEmpty,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emergency Expenses")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("➕ Log Emergency Expense",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: "Amount (₱)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter amount' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: "Note (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        "Date: ${DateFormat.yMMMMd().format(_selectedDate)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(Icons.check),
                      label: Text("Add Emergency Expense"),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Divider(),
            Text("📋 Emergency History",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (_emergencies.isEmpty)
              Center(
                child: Text("No emergency expenses logged yet."),
              )
            else
              ..._emergencies.map(_buildEmergencyItem),
          ],
        ),
      ),
    );
  }
}
