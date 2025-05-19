import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/allowance_provider.dart';
import 'set_category_limits_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currencyOptions = ['₱ PHP', '\$ USD', '€ EUR'];
  String? _avatarBase64;
  int userId = 1;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadInitialAllowance();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser(userId);
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    setState(() {
      _nameController.text = user['name'] ?? '';
      _avatarBase64 = user['avatar'];
    });
    if (user['currency'] != null) {
      currencyProvider.setCurrency(user['currency']);
    }
  }

  Future<void> _loadInitialAllowance() async {
    await Provider.of<AllowanceProvider>(context, listen: false)
        .loadAllowance(userId);
  }

  Future<void> _saveProfile() async {
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    final success = await ApiService.updateUser(
      userId: userId,
      name: _nameController.text,
      avatar: _avatarBase64 ?? '',
      currency: currencyProvider.currency,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Profile updated' : '❌ Failed to update'),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _avatarBase64 = base64Encode(bytes));
    }
  }

  Widget _buildAllowanceSection(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final allowanceProvider = Provider.of<AllowanceProvider>(context);

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.attach_money,
              color: Theme.of(context).colorScheme.primary),
          title: Text(
            "Current Allowance",
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            "${currencyProvider.symbol}${allowanceProvider.currentAllowance.toStringAsFixed(2)}",
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black54,
            ),
          ),
          trailing: Text(
            "Since ${DateFormat.yMMMd().format(allowanceProvider.startDate)}",
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black45,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () => _showAllowanceDialog(context),
            child: Text("Modify Allowance"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 36),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Divider(
          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
        ),
      ],
    );
  }

  void _showAllowanceDialog(BuildContext context) {
    final allowanceProvider =
        Provider.of<AllowanceProvider>(context, listen: false);
    final amountController = TextEditingController(
        text: allowanceProvider.currentAllowance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modify Allowance"),
        content: TextFormField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: "New Allowance Amount",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text) ?? 0;
              if (newAmount > 0) {
                final success = await allowanceProvider.updateAllowance(
                  userId: userId,
                  newAmount: newAmount,
                );

                if (success) {
                  // Force refresh of dashboard data
                  await Provider.of<AllowanceProvider>(context, listen: false)
                      .loadAllowance(userId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("✅ Allowance updated!")),
                  );
                  Navigator.pop(context);
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Failed to update")),
                  );
                }
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final avatarWidget = _avatarBase64 != null && _avatarBase64!.isNotEmpty
        ? CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(_avatarBase64!)),
          )
        : const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: avatarWidget,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Tap avatar to change",
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: currencyProvider.currency,
                items: _currencyOptions
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    currencyProvider.setCurrency(val);
                  }
                },
                decoration: InputDecoration(
                  labelText: "Preferred Currency",
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.settings, color: colorScheme.primary),
                title: Text(
                  "Set Category Limits",
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SetCategoryLimitsScreen()),
                  );
                },
              ),
              Consumer<AllowanceProvider>(
                builder: (context, allowanceProvider, child) {
                  return _buildAllowanceSection(context);
                },
              ),
              SwitchListTile(
                title: Text(
                  "Dark Mode",
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                  ),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: colorScheme.primary,
              ),
              ListTile(
                title: Text(
                  "Theme Color",
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                  ),
                ),
                trailing: DropdownButton<ColorSelection>(
                  value: themeProvider.selectedColor,
                  onChanged: (ColorSelection? newValue) {
                    if (newValue != null) {
                      themeProvider.setColor(newValue);
                    }
                  },
                  items: ColorSelection.values.map((ColorSelection color) {
                    return DropdownMenuItem<ColorSelection>(
                      value: color,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: color.color,
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          Text(
                            color.label,
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasing on String {
  String capitalize() =>
      isNotEmpty ? this[0].toUpperCase() + substring(1) : this;
}
