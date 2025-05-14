import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SetCategoryLimitsScreen extends StatefulWidget {
  @override
  State<SetCategoryLimitsScreen> createState() =>
      _SetCategoryLimitsScreenState();
}

class _SetCategoryLimitsScreenState extends State<SetCategoryLimitsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();

  String _selectedDuration = 'monthly';
  final List<String> _durations = ['daily', 'weekly', 'monthly'];
  Map<String, double> _limits = {};
  int userId = 1;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final limits =
        await ApiService.getCategoryLimits(userId, _selectedDuration);
    setState(() {
      _limits = limits;
    });
  }

  Future<void> _saveLimit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final category = _categoryController.text.trim();
      final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;

      final success = await ApiService.setCategoryLimit(
        userId: userId,
        category: category,
        limitAmount: limit,
        duration: _selectedDuration,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Limit saved for $category ($_selectedDuration)"),
        ));
        _categoryController.clear();
        _limitController.clear();
        _loadLimits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to save limit")),
        );
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Category Limits")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Duration Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              decoration: InputDecoration(
                labelText: "Duration",
                border: OutlineInputBorder(),
              ),
              items: _durations
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.capitalize()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDuration = value);
                  _loadLimits();
                }
              },
            ),
            SizedBox(height: 20),

            // Input Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? "Enter a category"
                        : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _limitController,
                    decoration: InputDecoration(
                      labelText: "Limit Amount (₱)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? "Enter a limit amount"
                        : null,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text("Save Limit"),
                      onPressed: _saveLimit,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 30),

            // Display of Current Limits
            Expanded(
              child: _limits.isEmpty
                  ? Center(child: Text("No limits set for this duration."))
                  : ListView(
                      children: _limits.entries.map((entry) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.category),
                            title: Text(entry.key),
                            subtitle: Text(
                              "Limit: ₱${entry.value.toStringAsFixed(2)} ($_selectedDuration)",
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// String capitalization extension
extension StringCasing on String {
  String capitalize() =>
      isNotEmpty ? this[0].toUpperCase() + substring(1) : this;
}
