import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/currency_provider.dart';
import '../providers/allowance_provider.dart';

class ExpenseLogAndHistoryScreen extends StatefulWidget {
  const ExpenseLogAndHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseLogAndHistoryScreen> createState() =>
      _ExpenseLogAndHistoryScreenState();
}

class _ExpenseLogAndHistoryScreenState
    extends State<ExpenseLogAndHistoryScreen> {
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
  List<Map<String, dynamic>> _expenses = [];
  int userId = 1;
  Map<String, double> _categoryLimits = {};
  String _selectedDuration = 'monthly';
  int? _editingExpenseId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadExpenses();
    await _loadCategoryLimits();
  }

  Future<void> _loadExpenses() async {
    final data = await ApiService.getExpenses(userId);
    setState(() => _expenses = data);
  }

  Future<void> _loadCategoryLimits() async {
    final limits =
        await ApiService.getCategoryLimits(userId, _selectedDuration);
    setState(() => _categoryLimits = limits);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final category = _selectedCategory == 'Custom'
        ? _customCategoryController.text.trim()
        : _selectedCategory;
    final amount = double.parse(_amountController.text.trim());
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Get current allowance data
    final allowanceProvider =
        Provider.of<AllowanceProvider>(context, listen: false);
    final currentBalance = allowanceProvider.remainingBalance;

    // Check if balance would go negative (for new expenses only)
    if (_editingExpenseId == null && currentBalance - amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ This expense would make your balance negative!'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check category limit
    if (_categoryLimits.containsKey(category)) {
      // Calculate total spending in this category (excluding current edit if applicable)
      double categorySpending = _expenses
          .where((e) =>
              e['category'] == category &&
              (_editingExpenseId == null || e['id'] != _editingExpenseId))
          .fold<double>(0,
              (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0));

      final categoryLimit = _categoryLimits[category] ?? 0;

      // Check if adding this expense would exceed the limit
      if ((categorySpending + amount) > categoryLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Cannot add expense. $category limit would be exceeded (${categorySpending + amount} > $categoryLimit)'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    bool success;
    if (_editingExpenseId != null) {
      success = await ApiService.updateExpense({
        'id': _editingExpenseId,
        'user_id': userId,
        'category': category,
        'amount': amount,
        'date': formattedDate,
        'note': _noteController.text.trim(),
      });
    } else {
      success = await ApiService.addExpense(
        userId: userId,
        category: category,
        amount: amount,
        date: formattedDate,
        note: _noteController.text.trim(),
      );
    }

    if (success) {
      // Refresh all data
      await allowanceProvider.loadAllowance(userId);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '✅ Expense ${_editingExpenseId != null ? 'updated' : 'added'} successfully')),
      );

      // Reset form
      _amountController.clear();
      _noteController.clear();
      _customCategoryController.clear();
      setState(() => _editingExpenseId = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '❌ Failed to ${_editingExpenseId != null ? 'update' : 'add'} expense')),
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

  void _editExpense(Map<String, dynamic> expense) {
    setState(() {
      _editingExpenseId = int.parse(expense['id'].toString());
      _selectedCategory = expense['category'];
      _amountController.text = expense['amount'].toString();
      _noteController.text = expense['note'] ?? '';
      _selectedDate = DateTime.parse(expense['expense_date']);
    });
  }

  Future<void> _deleteExpense(int id) async {
    final allowanceProvider =
        Provider.of<AllowanceProvider>(context, listen: false);
    await ApiService.deleteExpense(id);
    await allowanceProvider.loadAllowance(userId);
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Expense deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingExpenseId != null
                        ? "Edit Expense"
                        : "Add New Expense",
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _defaultCategories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                          decoration: InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                        ),
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
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: "Amount (${currencyProvider.symbol})",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter amount'
                              : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: "Note (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              "Date: ${DateFormat.yMMMMd().format(_selectedDate)}"),
                          trailing: Icon(Icons.calendar_today),
                          onTap: _pickDate,
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: Icon(Icons.check),
                            label: Text(_editingExpenseId != null
                                ? "Update Expense"
                                : "Add Expense"),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_editingExpenseId != null) ...[
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _editingExpenseId = null;
                                  _amountController.clear();
                                  _noteController.clear();
                                  _customCategoryController.clear();
                                });
                              },
                              child: Text("Cancel Edit"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 16),
                  Text(
                    "Expense History",
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          if (_expenses.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text("No expenses logged yet.")),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exp = _expenses[index];
                  final category = exp['category'];
                  final amount =
                      double.tryParse(exp['amount'].toString()) ?? 0.0;
                  final date = exp['expense_date'];
                  final note = exp['note'] ?? '';

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(
                        "$category - ${currencyProvider.symbol}${amount.toStringAsFixed(2)}",
                      ),
                      subtitle: Text(note.isNotEmpty ? "$date • $note" : date),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editExpense(exp),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(
                                int.parse(exp['id'].toString())),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _expenses.length,
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              Navigator.pop(context);
              await _deleteExpense(id);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }
}
