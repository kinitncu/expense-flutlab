import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/theme_provider.dart';
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
  String _selectedCurrency = '₱ PHP';
  String? _avatarBase64;
  int userId = 1;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser(userId);
    setState(() {
      _nameController.text = user['name'] ?? '';
      _selectedCurrency = user['currency'] ?? '₱ PHP';
      _avatarBase64 = user['avatar'];
    });
  }

  Future<void> _saveProfile() async {
    final success = await ApiService.updateUser(
      userId: userId,
      name: _nameController.text,
      avatar: _avatarBase64 ?? '',
      currency: _selectedCurrency,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Profile updated successfully'
            : 'Failed to update profile'),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _avatarBase64 = base64Encode(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _avatarBase64 != null && _avatarBase64!.isNotEmpty
        ? CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(_avatarBase64!)),
          )
        : const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          );

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: avatarWidget,
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text("Tap avatar to change")),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: _currencyOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCurrency = val!),
                decoration:
                    const InputDecoration(labelText: "Preferred Currency"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save Changes"),
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Set Category Limits"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SetCategoryLimitsScreen()),
                  );
                },
              ),
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
