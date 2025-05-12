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
      _avatarBase64 = base64Encode(bytes);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    print("Submitting setup form...");

    if (!_formKey.currentState!.validate()) {
      print("Form is invalid");
      return;
    }
    if (_avatarBase64 == null) {
      print("No avatar selected");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an avatar image.')),
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

    print("Insert user response: $userId");

    if (userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile.')),
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
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 30),
              Center(
                child: Text(
                  "Set Up Your Profile",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Center(child: avatarWidget),
              ),
              SizedBox(height: 10),
              Center(child: Text("Tap avatar to select picture")),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Your Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email (optional)"),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(labelText: "Preferred Currency"),
                items: _currencyOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCurrency = val!),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                child: Text("Save & Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
