import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({Key? key}) : super(key: key);

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currencyOptions = ['₱ PHP', '\$ USD', '€ EUR'];

  String _selectedCurrency = '₱ PHP';
  String? _avatarBase64;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _avatarBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_avatarBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a profile picture.')),
      );
      return;
    }

    final userId = await ApiService.insertUser(
      name: _nameController.text.trim(),
      avatar: _avatarBase64!,
      currency: _selectedCurrency,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    if (userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _avatarBase64 != null
        ? CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(_avatarBase64!)),
          )
        : CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(height: 30),
                Center(
                  child: Text(
                    "Set Up Your Profile",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Avatar Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Center(child: avatarWidget),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "Tap to select avatar",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
                SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Your Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 14),

                // Currency Picker
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: "Preferred Currency",
                    border: OutlineInputBorder(),
                  ),
                  items: _currencyOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCurrency = val!),
                ),
                SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: Icon(Icons.check_circle),
                    label: Text("Save & Continue"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
