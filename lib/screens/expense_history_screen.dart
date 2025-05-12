import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final data = await ApiService.getExpenses(1); // User ID
    setState(() => _expenses = data);
  }

  void _showEditDialog(Map<String, dynamic> expense) {
    final categoryController = TextEditingController(text: expense['category']);
    final amountController = TextEditingController(text: expense['amount']);
    final noteController = TextEditingController(text: expense['note']);
    final dateController = TextEditingController(text: expense['expense_date']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: 'Category')),
            TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number),
            TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
            TextField(
                controller: noteController,
                decoration: InputDecoration(labelText: 'Note')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final updated = {
                "id": int.parse(expense['id']),
                "category": categoryController.text,
                "amount": double.parse(amountController.text),
                "date": dateController.text,
                "note": noteController.text,
              };

              bool success = await ApiService.updateExpense(updated);
              if (success) {
                Navigator.pop(context);
                _loadExpenses();
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
            onPressed: () async {
              await ApiService.deleteExpense(id);
              Navigator.pop(context);
              _loadExpenses();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Expense History")),
      body: ListView.builder(
        itemCount: _expenses.length,
        itemBuilder: (_, index) {
          final exp = _expenses[index];
          return ListTile(
            title: Text("${exp['category']} - ₱${exp['amount']}"),
            subtitle: Text("${exp['expense_date']} • ${exp['note']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showEditDialog(exp)),
                IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(int.parse(exp['id']))),
              ],
            ),
          );
        },
      ),
    );
  }
}
