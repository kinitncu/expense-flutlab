import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  List<Map<String, dynamic>> _expenses = [];
  int userId = 1;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final data = await ApiService.getExpenses(userId);
    setState(() => _expenses = data);
  }

  void _showEditDialog(Map<String, dynamic> expense) {
    final categoryController = TextEditingController(text: expense['category']);
    final amountController =
        TextEditingController(text: expense['amount'].toString());
    final noteController = TextEditingController(text: expense['note']);
    final dateController = TextEditingController(text: expense['expense_date']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Expense'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              TextField(
                controller: noteController,
                decoration: InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = {
                "id": int.parse(expense['id'].toString()),
                "category": categoryController.text.trim(),
                "amount": double.tryParse(amountController.text) ?? 0.0,
                "date": dateController.text.trim(),
                "note": noteController.text.trim(),
              };

              bool success = await ApiService.updateExpense(updated);
              if (success) {
                Navigator.pop(context);
                _loadExpenses();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update expense')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await ApiService.deleteExpense(id);
              Navigator.pop(context);
              _loadExpenses();
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat.yMMMMd().format(date);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Expense History")),
      body: _expenses.isEmpty
          ? Center(child: Text("No expenses logged yet."))
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (_, index) {
                final exp = _expenses[index];
                final category = exp['category'];
                final amount = double.tryParse(exp['amount'].toString()) ?? 0.0;
                final date = _formatDate(exp['expense_date']);
                final note = exp['note'] ?? '';

                return ListTile(
                  title: Text("$category - ₱${amount.toStringAsFixed(2)}"),
                  subtitle: Text(note.isNotEmpty ? "$date • $note" : date),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(exp),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(int.parse(exp['id'].toString())),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
