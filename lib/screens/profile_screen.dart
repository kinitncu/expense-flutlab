import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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
    _avatarBase64 = "test"; // <- for debugging only
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser(userId);
    _nameController.text = user['name'] ?? '';
    _selectedCurrency = user['currency'] ?? '₱ PHP';
    _avatarBase64 = user['avatar'];
    setState(() {});
  }

  Future<void> _saveProfile() async {
    final success = await ApiService.updateUser(
      userId: userId,
      name: _nameController.text,
      avatar: _avatarBase64 ?? '',
      currency: _selectedCurrency,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      _avatarBase64 = base64Encode(bytes);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _avatarBase64 != null && _avatarBase64!.isNotEmpty
        ? CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(_avatarBase64!)),
          )
        : CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          );

    return Scaffold(
      appBar: AppBar(title: Text("Profile Settings")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: avatarWidget,
                ),
              ),
              SizedBox(height: 10),
              Center(child: Text("Tap avatar to change")),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: _currencyOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCurrency = val!),
                decoration: InputDecoration(labelText: "Preferred Currency"),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _saveProfile, child: Text("Save")),
            ],
          ),
        ),
      ),
    );
  }
}
