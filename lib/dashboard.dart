// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:farmers_record/add_admin_dialog.dart';
import 'package:farmers_record/dashboard_content.dart';
import 'package:farmers_record/farmers_page.dart';
import 'package:farmers_record/main.dart';
import 'package:farmers_record/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? admin;
  final VoidCallback onLogout;

  const DashboardPage({
    super.key,
    this.admin,
    required this.onLogout,
  });

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  Widget _currentPage = const DashboardContent();
  String _activePage = 'Dashboard';

  void _navigateTo(Widget page, String pageName) {
    setState(() {
      _currentPage = page;
      _activePage = pageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 24, 24, 27)
          : const Color.fromARGB(255, 237, 237, 240),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color.fromARGB(255, 17, 17, 22)
                  : const Color.fromARGB(255, 226, 226, 229),
              image: const DecorationImage(
                image: AssetImage('assets/icons/logo2.png'),
                fit: BoxFit.cover, // Makes the image cover the entire header
                opacity: 0.3, // Optional: Adds transparency to the background
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 45,
                  height: 70,
                  child: Image.asset(
                    'assets/icons/logo.png',
                    fit: BoxFit.fill, // Fit cover to fill the container
                    alignment: Alignment.center, // Center the image
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Farmers Record System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  color: Colors.green, // White icons for better visibility
                  onPressed: () {
                    ThemeToggleProvider.of(context)?.toggleTheme();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  color: Colors.red, // White icons for better visibility
                  onPressed: widget.onLogout,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 200,
                  color: isDarkMode
                      ? const Color.fromARGB(255, 20, 20, 24)
                      : const Color.fromARGB(255, 232, 232, 234),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      NavigationListTile(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        isActive: _activePage == 'Dashboard',
                        isDarkMode: isDarkMode,
                        onTap: () =>
                            _navigateTo(const DashboardContent(), 'Dashboard'),
                      ),
                      NavigationListTile(
                        icon: Icons.person,
                        title: 'Farmers',
                        isActive: _activePage == 'Farmers',
                        isDarkMode: isDarkMode,
                        onTap: () =>
                            _navigateTo(const FarmersPage(), 'Farmers'),
                      ),
                      const Spacer(),
                      _AdminProfileFooter(admin: widget.admin),
                    ],
                  ),
                ),
                Expanded(
                  child: _currentPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Rest of the code (FarmerRankingWidget, NavigationListTile, _AdminProfileFooter) remains unchanged
class FarmerRankingWidget extends StatefulWidget {
  const FarmerRankingWidget({super.key});

  @override
  State<FarmerRankingWidget> createState() => _FarmerRankingWidgetState();
}

class _FarmerRankingWidgetState extends State<FarmerRankingWidget> {
  String selectedProduct = 'PALAY';
  int selectedYear = DateTime.now().year;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> rankedFarmers = [];
  final List<String> products = [
    'PALAY',
    'NIYOG',
    'SAGING',
    'HALAMANG UGAT',
    'PRUTAS',
    'GULAY'
  ];

  @override
  void initState() {
    super.initState();
    _loadRankedFarmers();
  }

  List<int> _getYearOptions() {
    final currentYear = DateTime.now().year;
    List<int> years = [];
    for (int year = 2024; year <= currentYear; year++) {
      years.add(year);
    }
    return years;
  }

  Future<void> _loadRankedFarmers() async {
    final respondentList = await _dbHelper.queryAllRespondents();
    List<Map<String, dynamic>> tempFarmers = [];

    for (var respondent in respondentList) {
      final products =
          await _dbHelper.queryProductsByRespondent(respondent['id']);
      final matchingProducts = products.where((p) {
        final harvestDate =
            DateTime.parse(p['crop_harvest_date_every_product']);
        return p['product_name'] == selectedProduct &&
            harvestDate.year == selectedYear;
      }).toList();

      if (matchingProducts.isNotEmpty) {
        int totalIncome = 0;
        for (var product in matchingProducts) {
          totalIncome +=
              (product['crop_harvest_income_every_product'] as num?)?.toInt() ??
                  0;
        }

        tempFarmers.add({
          'name': _formatName(respondent),
          'income': totalIncome,
          'avatar': respondent['profile_picture'] ?? '',
        });
      }
    }

    tempFarmers.sort((a, b) => b['income'].compareTo(a['income']));

    setState(() {
      rankedFarmers = tempFarmers;
    });
  }

  String _formatName(Map<String, dynamic> respondent) {
    String middleInitial = respondent['middle_name']?.isNotEmpty == true
        ? '${respondent['middle_name'][0]}. '
        : '';
    String suffix = respondent['suffix']?.isNotEmpty == true
        ? ' ${respondent['suffix']}'
        : '';
    return '${respondent['first_name']} $middleInitial${respondent['last_name']}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    final numberFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Farmer Rankings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Gilroy',
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: selectedProduct,
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    items: products.map((String product) {
                      return DropdownMenuItem<String>(
                        value: product,
                        child: Text(
                          product,
                          style: const TextStyle(fontFamily: 'Gilroy'),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedProduct = newValue;
                          _loadRankedFarmers();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: selectedYear,
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    items: _getYearOptions().map((int year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: const TextStyle(fontFamily: 'Gilroy'),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedYear = newValue;
                          _loadRankedFarmers();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: rankedFarmers.isEmpty
                ? Center(
                    child: Text(
                      'No data available for $selectedProduct in $selectedYear',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rankedFarmers.length,
                    itemBuilder: (context, index) {
                      final farmer = rankedFarmers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: farmer['avatar'].isNotEmpty
                                  ? FileImage(File(farmer['avatar']))
                                  : const AssetImage('assets/avatar1.png')
                                      as ImageProvider,
                              onBackgroundImageError: (_, __) =>
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farmer['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Gilroy',
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Income: ${numberFormat.format(farmer['income'])}',
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Builder(builder: (context) {
                              return CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green,
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Gilroy',
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class NavigationListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isDarkMode;
  final VoidCallback onTap;

  const NavigationListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isActive,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  NavigationListTileState createState() => NavigationListTileState();
}

class NavigationListTileState extends State<NavigationListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: widget.isActive
            ? (widget.isDarkMode ? Colors.grey[700] : Colors.grey[300])
            : _isHovered
                ? (widget.isDarkMode ? Colors.grey[800] : Colors.grey[200])
                : Colors.transparent,
        child: ListTile(
          leading: Icon(
            widget.icon,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _AdminProfileFooter extends StatefulWidget {
  final Map<String, dynamic>? admin;

  const _AdminProfileFooter({required this.admin});

  @override
  State<_AdminProfileFooter> createState() => _AdminProfileFooterState();
}

class _AdminProfileFooterState extends State<_AdminProfileFooter> {
  final bool _showMenu = false;

  void _showAddAdminDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddAdminDialog(),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    final imagePath = widget.admin?['profile_picture'];
    return PopupMenuButton(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add_admin',
          child: ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Add New Admin'),
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'add_admin') {
          _showAddAdminDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: imagePath != null && imagePath.isNotEmpty
                  ? FileImage(File(imagePath))
                  : null,
              child: imagePath == null || imagePath.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.admin?['username'] ?? 'Admin',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontFamily: 'Gilroy',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_showMenu)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _showAddAdminDialog,
                    child: const Text('Add New Admin'),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
