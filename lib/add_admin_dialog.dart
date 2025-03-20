// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:farmers_record/database_helper.dart';
import 'package:farmers_record/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path; // Alias the path package
import 'package:path_provider/path_provider.dart';

class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({super.key});

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedImagePath;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await DatabaseHelper.instance.insertAdmin({
        'username': _usernameController.text,
        'password': _passwordController.text,
        'profile_picture': _selectedImagePath ?? 'assets/default_avatar.png',
      });

      await showDialog(
        context: context,
        builder: (context) => _buildSuccessDialog(),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showMessageDialog(
        title: 'Error',
        content: 'Failed to create admin: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSuccessDialog() {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;

    return AlertDialog(
      backgroundColor:
          isDarkMode ? const Color.fromARGB(255, 38, 38, 42) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      title: Text(
        'Success!',
        style: TextStyle(
          fontFamily: 'Gilroy',
          color: isDarkMode ? Colors.green[200] : Colors.green[600],
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'New admin created successfully!',
        style: TextStyle(
          fontFamily: 'Gilroy',
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'OK',
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: isDarkMode ? Colors.blue[200] : Colors.blue[600],
            ),
          ),
        ),
      ],
    );
  }

  void _showMessageDialog({
    required String title,
    required String content,
    bool isError = false,
  }) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDarkMode ? const Color.fromARGB(255, 38, 38, 42) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.0,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            color: isError
                ? (isDarkMode ? Colors.red[200] : Colors.red[600])
                : (isDarkMode ? Colors.white : Colors.black),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            fontFamily: 'Gilroy',
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDarkMode ? Colors.blue[200] : Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        final tempPath = platformFile.path;

        if (tempPath != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(tempPath);
          final permanentPath = '${appDir.path}/$fileName';

          await File(tempPath).copy(permanentPath);

          setState(() {
            _selectedImagePath = permanentPath;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;

    return AlertDialog(
      backgroundColor:
          isDarkMode ? const Color.fromARGB(255, 38, 38, 42) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      title: const Text(
        'Create New Admin',
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 400,
        height: 350,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    child: _selectedImagePath != null
                        ? Image.file(File(_selectedImagePath!),
                            fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.green[700] : Colors.green,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.grey, width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Create Admin',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              foregroundColor: isDarkMode ? Colors.white : Colors.black,
              side: const BorderSide(color: Colors.grey, width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
