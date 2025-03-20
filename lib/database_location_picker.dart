// ignore_for_file: use_build_context_synchronously

import 'package:farmers_record/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;

class DatabaseLocationPicker extends StatefulWidget {
  final Future<Widget> Function(DatabaseHelper dbHelper) onDatabaseSelected;

  const DatabaseLocationPicker({super.key, required this.onDatabaseSelected});

  @override
  DatabaseLocationPickerState createState() => DatabaseLocationPickerState();
}

class DatabaseLocationPickerState extends State<DatabaseLocationPicker> {
  String? _selectedPath;
  final dbHelper = DatabaseHelper.instance;

  Future<void> _pickDatabaseLocation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners for dialog
          side: const BorderSide(
            color: Colors.green, // Border color for dialog
            width: 1.0,
          ),
        ),
        backgroundColor:
            const Color.fromARGB(255, 245, 245, 247), // Light background
        title: const Text(
          'Select Database Option',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Darker text color
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Minimize vertical space
          children: [
            const Text(
              'Would you like to use an existing database or create a new one?',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                color: Colors.black54, // Subtle text color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the cards
              children: [
                // "Use Existing Database" Card
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickExistingDatabase();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded card
                      side: const BorderSide(
                        color: Colors.green, // Green border
                        width: 1.5, // Slightly thicker border
                      ),
                    ),
                    color: Colors.white, // Card background
                    elevation: 2, // Slight elevation for depth
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 18), // Larger padding
                      child: Text(
                        'Use Existing Database',
                        style: TextStyle(
                          fontSize: 16, // Larger text
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Colors.green, // Text color matches border
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Spacing between cards
                // "Create New Database" Card
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _createNewDatabase();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded card
                      side: const BorderSide(
                        color: Colors.blue, // Blue border
                        width: 1.5, // Slightly thicker border
                      ),
                    ),
                    color: Colors.white, // Card background
                    elevation: 2, // Slight elevation for depth
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 18), // Larger padding
                      child: Text(
                        'Create New Database',
                        style: TextStyle(
                          fontSize: 16, // Larger text
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Colors.blue, // Text color matches border
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExistingDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select an existing database file',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result != null && result.files.isNotEmpty) {
      String selectedFilePath = result.files.single.path!;
      if (selectedFilePath.endsWith('farmer_db.db')) {
        setState(() {
          _selectedPath = selectedFilePath;
        });
        dbHelper.setCustomDatabasePath(selectedFilePath);
        await dbHelper.database; // Ensure database is initialized
        final nextScreen = await widget.onDatabaseSelected(dbHelper);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a file named "farmer_db.db"'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _createNewDatabase() async {
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a folder to store the new database',
    );
    if (result != null) {
      String dbPath = join(result, 'farmer_db.db');
      setState(() {
        _selectedPath = dbPath;
      });
      dbHelper.setCustomDatabasePath(dbPath);
      await dbHelper.database; // Ensure database is initialized
      final nextScreen = await widget.onDatabaseSelected(dbHelper);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 237, 240),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Database Location',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose an existing database file or a folder to create a new database.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickDatabaseLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Browse',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedPath != null)
                Text(
                  'Selected: $_selectedPath',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
