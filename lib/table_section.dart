import 'package:farmers_record/main.dart';
import 'package:farmers_record/printing_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'database_helper.dart';
import 'dart:io';

class Respondent {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final int age;
  final String avatarPath;
  final double area;
  final int cropCount;
  final int? productIncomePerYear;

  Respondent.fromMap(Map<String, dynamic> respondent,
      Map<String, dynamic> product, int count, int? income)
      : id = respondent['id'] as int,
        firstName = respondent['first_name'] as String,
        middleName = respondent['middle_name'] as String? ?? '',
        lastName = respondent['last_name'] as String,
        suffix = respondent['suffix'] as String? ?? '',
        age = respondent['age'] as int,
        avatarPath = respondent['profile_picture'] as String? ?? '',
        area =
            (product['area_hectares_every_product'] as num?)?.toDouble() ?? 0.0,
        cropCount = count,
        productIncomePerYear = income;
}

class TableSection extends StatefulWidget {
  const TableSection({super.key});

  @override
  TableSectionState createState() => TableSectionState();
}

class TableSectionState extends State<TableSection> {
  List<Respondent> respondents = [];
  List<Respondent> filteredRespondents = [];
  String selectedProduct = 'NIYOG';
  int selectedYear = DateTime.now().year;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRespondents(selectedProduct, selectedYear);
    _searchController.addListener(_filterRespondents);
  }

  List<int> _getYearOptions() {
    final currentYear = DateTime.now().year;
    List<int> years = [];
    for (int year = 2024; year <= currentYear; year++) {
      years.add(year);
    }
    return years;
  }

  Future<void> _loadRespondents(String productName, int year) async {
    final respondentList = await _dbHelper.queryAllRespondents();
    List<Respondent> tempRespondents = [];

    for (var respondent in respondentList) {
      final products =
          await _dbHelper.queryProductsByRespondent(respondent['id']);
      final matchingProducts = products.where((p) {
        final harvestDate =
            DateTime.parse(p['crop_harvest_date_every_product']);
        return p['product_name'] == productName && harvestDate.year == year;
      }).toList();

      if (matchingProducts.isNotEmpty) {
        int productIncome = 0;
        for (var product in matchingProducts) {
          productIncome +=
              (product['crop_harvest_income_every_product'] as num?)?.toInt() ??
                  0;
        }

        tempRespondents.add(Respondent.fromMap(
          respondent,
          matchingProducts.first,
          matchingProducts.length,
          productIncome,
        ));
      }
    }

    setState(() {
      respondents = tempRespondents;
      selectedProduct = productName;
      selectedYear = year;
      _filterRespondents();
    });
  }

  Future<void> _refreshData() async {
    await _loadRespondents(selectedProduct, selectedYear);
  }

  void _filterRespondents() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredRespondents = List.from(respondents);
      } else {
        filteredRespondents = respondents.where((r) {
          final fullName = formatName(r).toLowerCase();
          return fullName.contains(query);
        }).toList();
      }
    });
  }

  String formatName(Respondent r) {
    String middleInitial =
        r.middleName.isNotEmpty ? '${r.middleName[0]}. ' : '';
    String suffix = r.suffix.isNotEmpty ? ' ${r.suffix}' : '';
    return '${r.firstName} $middleInitial${r.lastName}$suffix';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    final numberFormat = NumberFormat.decimalPattern();

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        color: isDarkMode
            ? const Color.fromARGB(255, 38, 38, 42)
            : const Color.fromRGBO(245, 245, 247, 1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Year: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: _getYearOptions().map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _loadRespondents(selectedProduct, value);
                      }
                    },
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.print,
                            color: isDarkMode ? Colors.white : Colors.black),
                        onSelected: (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrintingPage(
                                respondents: filteredRespondents,
                                selectedProduct: selectedProduct,
                                selectedYear: selectedYear,
                                allProducts: value == 'all',
                              ),
                            ),
                          );
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'single',
                            child: Text('Print Selected Product'),
                          ),
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('Print All Products'),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: isDarkMode ? Colors.white : Colors.black),
                        onPressed: _refreshData,
                        tooltip: 'Refresh Data',
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search farmers...',
                            hintStyle: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            prefixIcon: Icon(Icons.search,
                                size: 20,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: isDarkMode
                  ? const Color.fromARGB(255, 24, 24, 27)
                  : const Color.fromARGB(255, 255, 255, 255),
              child: Row(
                children: [
                  Expanded(
                      flex: 4,
                      child: Text('FULL NAME',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy',
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54))),
                  Expanded(
                      flex: 1,
                      child: Text('AGE',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy',
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54))),
                  Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Text('PRODUCT',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Gilroy',
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54)),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.arrow_drop_down_outlined,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                            onSelected: (value) =>
                                _loadRespondents(value, selectedYear),
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                  value: 'PALAY', child: Text('PALAY')),
                              const PopupMenuItem(
                                  value: 'NIYOG', child: Text('NIYOG')),
                              const PopupMenuItem(
                                  value: 'SAGING', child: Text('SAGING')),
                              const PopupMenuItem(
                                  value: 'HALAMANG UGAT',
                                  child: Text('HALAMANG UGAT')),
                              const PopupMenuItem(
                                  value: 'PRUTAS', child: Text('PRUTAS')),
                              const PopupMenuItem(
                                  value: 'GULAY', child: Text('GULAY')),
                            ],
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 2,
                      child: Text('AREA (SQM)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy',
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54))),
                  Expanded(
                      flex: 3,
                      child: Text('CROP/HARVEST COUNT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy',
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54))),
                  Expanded(
                      flex: 3,
                      child: Text('INCOME PER YEAR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gilroy',
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LiquidPullToRefresh(
                onRefresh: _refreshData,
                color: Colors.green, // Green loading progress color
                backgroundColor: Colors.white,
                showChildOpacityTransition: false,
                animSpeedFactor: 2.0,
                child: filteredRespondents.isEmpty
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
                    : ListView.builder(
                        itemCount: filteredRespondents.length,
                        itemBuilder: (context, index) {
                          final r = filteredRespondents[index];
                          return Card(
                            color: isDarkMode
                                ? const Color.fromARGB(255, 34, 34, 36)
                                : const Color.fromRGBO(238, 238, 241, 1),
                            margin: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: isDarkMode
                                      ? const Color.fromARGB(255, 60, 60, 62)
                                      : const Color.fromARGB(
                                          255, 255, 255, 255),
                                  width: 0.7),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 4,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: r
                                                    .avatarPath.isNotEmpty
                                                ? FileImage(File(r.avatarPath))
                                                : const AssetImage(
                                                        'assets/avatar1.png')
                                                    as ImageProvider,
                                            onBackgroundImageError: (_, __) =>
                                                const Icon(Icons.person,
                                                    color: Colors.grey),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(formatName(r),
                                                  style: TextStyle(
                                                      fontFamily: 'Gilroy',
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black)),
                                              Text('ID: ${r.id}',
                                                  style: TextStyle(
                                                      fontFamily: 'Gilroy',
                                                      fontSize: 12,
                                                      color: isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600])),
                                            ],
                                          ),
                                        ],
                                      )),
                                  Expanded(
                                      flex: 1,
                                      child: Text(r.age.toString(),
                                          style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(selectedProduct,
                                          style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('${r.area} has.',
                                          style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black))),
                                  Expanded(
                                      flex: 3,
                                      child: Text(
                                          numberFormat.format(r.cropCount),
                                          style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black))),
                                  Expanded(
                                      flex: 3,
                                      child: Text(
                                          numberFormat.format(
                                              r.productIncomePerYear ?? 0),
                                          style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
