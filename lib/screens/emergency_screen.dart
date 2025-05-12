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
  double _amount = 0;
  String _note = '';
  DateTime _selectedDate = DateTime.now();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final success = await ApiService.logEmergency(
        userId: 1,
        amount: _amount,
        date: date,
        note: _note,
      );
      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Emergency Logged")));
        _formKey.currentState!.reset();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to log emergency")));
      }
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Amount"),
              validator: (val) =>
                  val == null || val.isEmpty ? "Required" : null,
              onSaved: (val) => _amount = double.parse(val!),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Note"),
              onSaved: (val) => _note = val ?? '',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${DateFormat.yMMMd().format(_selectedDate)}"),
                TextButton(onPressed: _pickDate, child: Text("Pick Date"))
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text("Log Emergency")),
          ]),
        ),
      ),
    );
  }
}
