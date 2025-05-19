import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/currency_provider.dart';
import '../providers/category_limit_provider.dart';

class SetCategoryLimitsScreen extends StatefulWidget {
  @override
  State<SetCategoryLimitsScreen> createState() =>
      _SetCategoryLimitsScreenState();
}

class _SetCategoryLimitsScreenState extends State<SetCategoryLimitsScreen> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  int userId = 1;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'School',
    'Health',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<CategoryLimitProvider>(context, listen: false)
        .loadLimits(userId);
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final limitProvider = Provider.of<CategoryLimitProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Set Category Limits"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Duration selector
            DropdownButton<String>(
              value: limitProvider.selectedDuration,
              items: ['daily', 'weekly', 'monthly'].map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration.capitalize()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  limitProvider.setDuration(value);
                  limitProvider.loadLimits(userId);
                }
              },
              isExpanded: true,
            ),
            SizedBox(height: 20),

            // Category selector
            DropdownButton<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _amountController.text =
                        limitProvider.limits[value]?.toStringAsFixed(2) ?? '';
                  });
                }
              },
              isExpanded: true,
            ),
            SizedBox(height: 20),

            // Amount input
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: "Limit Amount (${currencyProvider.symbol})",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(_amountController.text) ?? 0;
                      if (amount > 0) {
                        final success = await limitProvider.setLimit(
                          userId: userId,
                          category: _selectedCategory,
                          limit: amount,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(success
                                  ? "✅ Limit saved successfully!"
                                  : "❌ Failed to save limit")),
                        );
                      }
                    },
                    child: Text("Save Limit"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        limitProvider.limits.containsKey(_selectedCategory)
                            ? () async {
                                final success = await limitProvider.removeLimit(
                                  userId: userId,
                                  category: _selectedCategory,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(success
                                          ? "✅ Limit removed!"
                                          : "❌ Failed to remove limit")),
                                );
                              }
                            : null,
                    child: Text("Remove Limit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Current limits
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final hasLimit = limitProvider.limits.containsKey(category);
                  final limit = limitProvider.limits[category] ?? 0;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(category),
                      subtitle: Text(hasLimit
                          ? "${currencyProvider.symbol}${limit.toStringAsFixed(2)} (${limitProvider.selectedDuration.capitalize()})"
                          : "No limit set"),
                      trailing: hasLimit
                          ? IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final success = await limitProvider.removeLimit(
                                  userId: userId,
                                  category: category,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(success
                                          ? "✅ Limit removed!"
                                          : "❌ Failed to remove limit")),
                                );
                              },
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasing on String {
  String capitalize() =>
      isNotEmpty ? this[0].toUpperCase() + substring(1) : this;
}
