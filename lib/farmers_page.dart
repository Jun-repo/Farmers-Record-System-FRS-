import 'package:farmers_record/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';
import 'dart:io';

class FarmersPage extends StatefulWidget {
  const FarmersPage({super.key});

  @override
  State<FarmersPage> createState() => _FarmersPageState();
}

class _FarmersPageState extends State<FarmersPage>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _genderController = TextEditingController();
  final _spouseController = TextEditingController();
  final _spouseDobController = TextEditingController();
  final _spouseGenderController = TextEditingController();

  // FocusNodes for farmer form
  final _firstNameFocus = FocusNode();
  final _middleNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _genderFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _spouseFocus = FocusNode();
  final _spouseGenderFocus = FocusNode();
  final _spouseDobFocus = FocusNode();

  List<Map<String, dynamic>> _farmers = [];
  List<Map<String, dynamic>> _filteredFarmers = [];
  final _searchController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));
    _loadFarmers();
    _searchController.addListener(_filterFarmers);
  }

  Future<void> _loadFarmers() async {
    final farmers = await _dbHelper.queryAllRespondents();
    setState(() {
      _farmers = farmers;
      _filteredFarmers = List.from(farmers);
    });
  }

  void _filterFarmers() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFarmers = List.from(_farmers);
      } else {
        _filteredFarmers = _farmers.where((farmer) {
          final fullName =
              '${farmer['first_name']} ${farmer['middle_name'] ?? ''} ${farmer['last_name']}'
                  .toLowerCase();
          return fullName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  int _calculateAgeFromDate(DateTime dob) {
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _showAddFarmerOverlay({bool isEdit = false, int? farmerId}) {
    if (_overlayEntry != null) {
      _hideOverlay();
    }

    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
              onTap: _hideOverlay, child: Container(color: Colors.black54)),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.4,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  elevation: 8,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isEdit ? 'Edit Farmer' : 'Add New Farmer',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Gilroy')),
                                IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _hideOverlay),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: _pickFile,
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.black54),
                                  ),
                                  child: _selectedImage != null
                                      ? Image.file(_selectedImage!,
                                          fit: BoxFit.cover)
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo,
                                                color: isDarkMode
                                                    ? Colors.white60
                                                    : Colors.black54),
                                            Text('Add Photo',
                                                style: TextStyle(
                                                    fontFamily: 'Gilroy',
                                                    color: isDarkMode
                                                        ? Colors.white60
                                                        : Colors.black54)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _firstNameController,
                              focusNode: _firstNameFocus,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                hintText: 'Enter first name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Required' : null,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_middleNameFocus),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _middleNameController,
                              focusNode: _middleNameFocus,
                              decoration: const InputDecoration(
                                labelText: 'Middle Name',
                                hintText: 'Enter middle name',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_lastNameFocus),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lastNameController,
                              focusNode: _lastNameFocus,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                hintText: 'Enter last name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Required' : null,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_genderFocus),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _genderController,
                                    focusNode: _genderFocus,
                                    decoration: const InputDecoration(
                                      labelText: 'Gender',
                                      hintText: 'e.g., Male/Female',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value!.isEmpty ? 'Required' : null,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context)
                                            .requestFocus(_dobFocus),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _dobController,
                                        focusNode: _dobFocus,
                                        decoration: const InputDecoration(
                                          labelText: 'Date of Birth',
                                          hintText: 'YYYY-MM-DD',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) =>
                                            value!.isEmpty ? 'Required' : null,
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) =>
                                            FocusScope.of(context)
                                                .requestFocus(_addressFocus),
                                        onChanged: (value) {
                                          try {
                                            DateTime dob =
                                                DateTime.parse(value);
                                            int age =
                                                _calculateAgeFromDate(dob);
                                            _ageController.text =
                                                age.toString();
                                          } catch (e) {
                                            _ageController.text = '';
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _ageController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Age',
                                      hintText: 'Auto-calculated',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              focusNode: _addressFocus,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                hintText: 'Enter full address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Required' : null,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(_spouseFocus),
                            ),
                            const SizedBox(height: 12),
                            ExpansionTile(
                              title: const Text('Spouse Information'),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _spouseController,
                                        focusNode: _spouseFocus,
                                        decoration: const InputDecoration(
                                          labelText: 'Spouse Name',
                                          hintText: 'Enter spouse name',
                                          border: OutlineInputBorder(),
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) =>
                                            FocusScope.of(context).requestFocus(
                                                _spouseGenderFocus),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _spouseGenderController,
                                        focusNode: _spouseGenderFocus,
                                        decoration: const InputDecoration(
                                          labelText: 'Gender',
                                          hintText: 'e.g., Male/Female',
                                          border: OutlineInputBorder(),
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) =>
                                            FocusScope.of(context)
                                                .requestFocus(_spouseDobFocus),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _spouseDobController,
                                        focusNode: _spouseDobFocus,
                                        decoration: const InputDecoration(
                                          labelText: 'Date of Birth',
                                          hintText: 'YYYY-MM-DD',
                                          border: OutlineInputBorder(),
                                        ),
                                        textInputAction: TextInputAction.done,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Age',
                                          hintText: 'Enter age',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final respondent = {
                                      'id': isEdit ? farmerId : null,
                                      'profile_picture':
                                          _selectedImage?.path ?? '',
                                      'first_name': _firstNameController.text,
                                      'middle_name': _middleNameController.text,
                                      'last_name': _lastNameController.text,
                                      'age': int.parse(_ageController.text),
                                      'gender': _genderController.text,
                                      'address': _addressController.text,
                                      'spouse': _spouseController.text,
                                      'spouse_birthdate':
                                          _spouseDobController.text,
                                      'spouse_age': _spouseDobController
                                              .text.isNotEmpty
                                          ? _calculateAgeFromDate(
                                              DateTime.parse(
                                                  _spouseDobController.text))
                                          : null,
                                      'spouse_gender':
                                          _spouseGenderController.text,
                                    };
                                    if (isEdit) {
                                      await _dbHelper
                                          .updateRespondent(respondent);
                                    } else {
                                      await _dbHelper
                                          .insertRespondent(respondent);
                                    }
                                    await _loadFarmers();
                                    _hideOverlay();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.green[700]
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: Colors.grey, width: 1.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Farmer',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      _animationController.forward();
    }
  }

  void _showAddProductOverlay(String farmerId) {
    final productNameController = TextEditingController();
    final areaController = TextEditingController();
    final harvestDateController = TextEditingController();
    final incomeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // FocusNodes for product form
    final productNameFocus = FocusNode();
    final areaFocus = FocusNode();
    final harvestDateFocus = FocusNode();
    final incomeFocus = FocusNode();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
              onTap: _hideOverlay, child: Container(color: Colors.black54)),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.4,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  elevation: 8,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Add Product',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Gilroy')),
                              IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _hideOverlay),
                            ],
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: productNameController,
                                          focusNode: productNameFocus,
                                          decoration: const InputDecoration(
                                            labelText: 'Product Name',
                                            hintText: 'e.g., PALAY, NIYOG',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Product name is required';
                                            }
                                            return null;
                                          },
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .requestFocus(areaFocus),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: areaController,
                                          focusNode: areaFocus,
                                          decoration: const InputDecoration(
                                            labelText: 'Area (Hectares)',
                                            hintText: 'e.g., 2.5',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Area is required';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
                                              return 'Please enter a valid number';
                                            }
                                            if (double.parse(value) <= 0) {
                                              return 'Area must be greater than 0';
                                            }
                                            return null;
                                          },
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .requestFocus(
                                                      harvestDateFocus),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: harvestDateController,
                                          focusNode: harvestDateFocus,
                                          decoration: const InputDecoration(
                                            labelText: 'Harvest Date',
                                            hintText: 'YYYY-MM-DD',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Harvest date is required';
                                            }
                                            try {
                                              DateTime.parse(value);
                                              final regex = RegExp(
                                                  r'^\d{4}-\d{2}-\d{2}$');
                                              if (!regex.hasMatch(value)) {
                                                return 'Use YYYY-MM-DD format';
                                              }
                                            } catch (e) {
                                              return 'Invalid date format (YYYY-MM-DD)';
                                            }
                                            return null;
                                          },
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .requestFocus(incomeFocus),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: incomeController,
                                          focusNode: incomeFocus,
                                          decoration: const InputDecoration(
                                            labelText: 'Income',
                                            hintText: 'e.g., 50000',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Income is required';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Please enter a valid integer';
                                            }
                                            if (int.parse(value) < 0) {
                                              return 'Income cannot be negative';
                                            }
                                            return null;
                                          },
                                          textInputAction: TextInputAction.done,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final product = {
                                    'respondent_id': int.parse(farmerId),
                                    'product_name': productNameController.text
                                        .toUpperCase(),
                                    'area_hectares_every_product':
                                        double.tryParse(areaController.text),
                                    'crop_harvest_date_every_product':
                                        harvestDateController.text,
                                    'crop_harvest_income_every_product':
                                        int.tryParse(incomeController.text),
                                  };
                                  await _dbHelper.insertProduct(product);
                                  await _loadFarmers();
                                  _hideOverlay();

                                  // Dispose product FocusNodes
                                  productNameFocus.dispose();
                                  areaFocus.dispose();
                                  harvestDateFocus.dispose();
                                  incomeFocus.dispose();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Colors.grey, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save Product',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      _animationController.forward();
    }
  }

  void _hideOverlay() {
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _selectedImage = null;
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _dobController.clear();
      _ageController.clear();
      _addressController.clear();
      _genderController.clear();
      _spouseController.clear();
      _spouseDobController.clear();
      _spouseGenderController.clear();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    _spouseController.dispose();
    _spouseDobController.dispose();
    _spouseGenderController.dispose();
    _searchController.dispose();

    // Dispose farmer FocusNodes
    _firstNameFocus.dispose();
    _middleNameFocus.dispose();
    _lastNameFocus.dispose();
    _genderFocus.dispose();
    _dobFocus.dispose();
    _addressFocus.dispose();
    _spouseFocus.dispose();
    _spouseGenderFocus.dispose();
    _spouseDobFocus.dispose();

    super.dispose();
  }

  // Rest of the code (build method and other helper methods) remains unchanged
  // ...

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color.fromARGB(255, 24, 24, 27)
                : const Color.fromRGBO(238, 238, 241, 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Farmers List',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                      color: isDarkMode ? Colors.white : Colors.black)),
              ElevatedButton.icon(
                onPressed: _showAddFarmerOverlay,
                icon: const Icon(Icons.add),
                label: const Text('Add New Farmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color.fromARGB(255, 170, 170, 176)
                      : const Color.fromARGB(255, 60, 60, 62),
                  foregroundColor: isDarkMode
                      ? const Color.fromARGB(255, 24, 24, 27)
                      : const Color.fromRGBO(245, 245, 247, 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: BorderSide(
                      color: isDarkMode
                          ? const Color.fromRGBO(248, 248, 252, 1)
                          : const Color.fromARGB(255, 15, 15, 18),
                      width: 0.7),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search farmers by name...',
              hintStyle: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(Icons.search,
                  size: 20,
                  color: isDarkMode ? Colors.white60 : Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _filteredFarmers.isEmpty
                    ? Center(
                        child: Text(
                          'No farmers found',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _filteredFarmers.length,
                        itemBuilder: (context, index) {
                          final farmer = _filteredFarmers[index];
                          return Card(
                            color: isDarkMode
                                ? const Color.fromARGB(255, 38, 38, 42)
                                : const Color.fromRGBO(245, 245, 247, 1),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: isDarkMode
                                      ? const Color.fromARGB(255, 60, 60, 62)
                                      : const Color.fromARGB(
                                          255, 255, 255, 255),
                                  width: 0.7),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: farmer['profile_picture'] != null &&
                                            farmer['profile_picture'].isNotEmpty
                                        ? Image.file(
                                            File(farmer['profile_picture']),
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: isDarkMode
                                                ? const Color.fromARGB(
                                                    255, 38, 38, 42)
                                                : const Color.fromRGBO(
                                                    245, 245, 247, 1),
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: isDarkMode
                                                  ? const Color.fromARGB(
                                                      255, 60, 60, 62)
                                                  : const Color.fromARGB(
                                                      255, 255, 255, 255),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(1.0),
                                          Colors.black.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Spacer(),
                                      Text(
                                        '${farmer['first_name']} ${farmer['middle_name'] != null && farmer['middle_name'].isNotEmpty ? farmer['middle_name'][0] + '.' : ''} ${farmer['last_name']}',
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.normal,
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      _buildInfoItem(
                                          'Address: ${farmer['address'] ?? 'N/A'}',
                                          Icons.location_on,
                                          isDarkMode),
                                      const SizedBox(height: 12),
                                      _buildInfoItem1(
                                          'Age: ${farmer['age']}', isDarkMode),
                                      _buildInfoItem1(
                                          'Spouse: ${farmer['spouse'] ?? 'N/A'}',
                                          isDarkMode),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _showAddProductOverlay(
                                                      farmer['id'].toString()),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDarkMode
                                                    ? Colors.green
                                                    : Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  side: BorderSide(
                                                      color: isDarkMode
                                                          ? const Color
                                                              .fromARGB(255,
                                                              255, 255, 255)
                                                          : const Color
                                                              .fromARGB(255,
                                                              255, 255, 255),
                                                      width: 0.7),
                                                ),
                                              ),
                                              child: const Text('Add Product'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 0.7,
                                              ),
                                            ),
                                            child: PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_horiz,
                                                  color: Colors.white),
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                const PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: ListTile(
                                                    leading: Icon(Icons.edit),
                                                    title: Text('Edit'),
                                                  ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: ListTile(
                                                    leading: Icon(Icons.delete,
                                                        color: Colors.red),
                                                    title: Text('Delete',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ),
                                              ],
                                              onSelected: (String value) async {
                                                if (value == 'edit') {
                                                  _showEditFarmerOverlay(
                                                      farmer);
                                                } else if (value == 'delete') {
                                                  _showDeleteConfirmationDialog(
                                                      farmer['id']);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem1(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditFarmerOverlay(Map<String, dynamic> farmer) {
    if (_overlayEntry != null) {
      _hideOverlay();
    }

    _firstNameController.text = farmer['first_name'] ?? '';
    _middleNameController.text = farmer['middle_name'] ?? '';
    _lastNameController.text = farmer['last_name'] ?? '';
    _genderController.text = farmer['gender'] ?? '';
    _dobController.text = farmer['date_of_birth'] ?? '';
    _ageController.text = farmer['age']?.toString() ?? '';
    _addressController.text = farmer['address'] ?? '';
    _spouseController.text = farmer['spouse'] ?? '';
    _spouseDobController.text = farmer['spouse_birthdate'] ?? '';
    _spouseGenderController.text = farmer['spouse_gender'] ?? '';

    if (farmer['profile_picture'] != null &&
        farmer['profile_picture'].isNotEmpty) {
      _selectedImage = File(farmer['profile_picture']);
    } else {
      _selectedImage = null;
    }

    _showAddFarmerOverlay(isEdit: true, farmerId: farmer['id']);
  }

  void _showDeleteConfirmationDialog(int farmerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Farmer'),
          content: const Text(
              'Are you sure you want to delete this farmer and all associated products? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _dbHelper.deleteRespondent(farmerId);
                await _dbHelper.deleteProductsByRespondentId(farmerId);
                await _loadFarmers();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
